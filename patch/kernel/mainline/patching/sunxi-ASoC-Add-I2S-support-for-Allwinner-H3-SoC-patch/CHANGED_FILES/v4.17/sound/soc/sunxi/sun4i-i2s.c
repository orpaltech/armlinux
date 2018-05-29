// SPDX-License-Identifier: GPL-2.0+
/*
 * ALSA SoC I2S Audio Layer for Allwinner sunXi SoC
 *
 * Copyright 2018 Sergey Suloev <ssuloev@orpaltech.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#define DEBUG

#include <linux/clk.h>
#include <linux/dmaengine.h>
#include <linux/module.h>
#include <linux/of_device.h>
#include <linux/platform_device.h>
#include <linux/pm_runtime.h>
#include <linux/regmap.h>
#include <linux/reset.h>

#include <sound/dmaengine_pcm.h>
#include <sound/pcm_params.h>
#include <sound/soc.h>
#include <sound/soc-dai.h>

#include "sun4i-i2s.h"


static const struct sun4i_i2s_clkdiv sun4i_i2s_bclk_div[] = {
	{ .div = 2, .val = 0 },
	{ .div = 4, .val = 1 },
	{ .div = 6, .val = 2 },
	{ .div = 8, .val = 3 },
	{ .div = 12, .val = 4 },
	{ .div = 16, .val = 5 },
	{ .div = 32, .val = 6 },
	{ .div = 64, .val = 7 },
};

static const struct sun4i_i2s_clkdiv sun8i_i2s_clk_div[] = {
	{ .div = 1, .val = 1 },
	{ .div = 2, .val = 2 },
	{ .div = 4, .val = 3 },
	{ .div = 6, .val = 4 },
	{ .div = 8, .val = 5 },
	{ .div = 12, .val = 6 },
	{ .div = 16, .val = 7 },
	{ .div = 24, .val = 8 },
	{ .div = 32, .val = 9 },
	{ .div = 48, .val = 10 },
	{ .div = 64, .val = 11 },
	{ .div = 96, .val = 12 },
	{ .div = 128, .val = 13 },
	{ .div = 176, .val = 14 },
	{ .div = 192, .val = 15 },
};

static const struct sun4i_i2s_clkdiv sun4i_i2s_mclk_div[] = {
	{ .div = 1, .val = 0 },
	{ .div = 2, .val = 1 },
	{ .div = 4, .val = 2 },
	{ .div = 6, .val = 3 },
	{ .div = 8, .val = 4 },
	{ .div = 12, .val = 5 },
	{ .div = 16, .val = 6 },
	{ .div = 24, .val = 7 },
	{ .div = 32, .val = 8 },
	{ .div = 48, .val = 9 },
	{ .div = 64, .val = 10 },
};

static int sun4i_i2s_oversample_rates[] = {
	128,
	192,
	256,
	384,
	512,
	768,
};

static bool sun4i_i2s_is_oversample_valid(u32 oversample_rate)
{
	int i;

	for (i = 0; i < ARRAY_SIZE(sun4i_i2s_oversample_rates); i++)
		if (sun4i_i2s_oversample_rates[i] == oversample_rate)
			return true;

	return false;
}

static int sun4i_i2s_get_bclk_div(struct sun4i_i2s *i2s, u32 clk_rate,
				  u32 channels, u32 sample_rate, u32 word_size)
{
	int div, i;
	u32 bclk_rate, oversample;

	if (i2s->bclk_ratio) {
		bclk_rate = sample_rate * i2s->bclk_ratio;
		div = clk_rate / bclk_rate;
	} else {
		oversample = clk_rate / sample_rate;
		div = oversample / word_size / channels;

		bclk_rate = clk_rate / div;
		/* Calc BCLK ratio to find LRCK/SYNC period later on */
		i2s->bclk_ratio = bclk_rate / sample_rate;
	}

	for (i = 0; i < i2s->quirks->num_bclkdiv; i++) {
		if (i2s->quirks->bclk_div[i].div == div)
			return i2s->quirks->bclk_div[i].val;
	}

	return -EINVAL;
}

static int sun4i_i2s_get_mclk_div(struct sun4i_i2s *i2s, u32 clk_rate,
				  const struct sun4i_i2s_clkdiv *mdiv,
				  int size)
{
	int div = clk_rate / i2s->mclk_rate;
	int i;

	for (i = 0; i < size; i++) {
		if (mdiv->div == div)
			return mdiv->val;
		mdiv++;
	}

	return -EINVAL;
}

static inline u32 sun4i_i2s_field_get(struct sun4i_i2s *i2s, u32 index)
{
	struct regmap_field *field;
	u32 val;

	if (index >= REGMAP_NUM_FIELDS)
		return 0;

	field = i2s->fields[index];
	return !regmap_field_read(field, &val) ? val : 0;
}

static inline void sun4i_i2s_field_set(struct sun4i_i2s *i2s, u32 index, u32 val)
{
	struct regmap_field *field;

	if (index >= REGMAP_NUM_FIELDS)
		return;

	dev_dbg(i2s->dev,
		"write regmap: field = %d, val = 0x%08x\n",
		index, val);

	field = i2s->fields[index];
	regmap_field_write(field, val);
}

static int sun4i_i2s_setup_pll(struct sun4i_i2s *i2s, u32 sample_rate, u32 *clk_rate)
{
	int ret;

	/* cpu master */
	switch (sample_rate) {
	case 176400:
	case 88200:
	case 44100:
	case 22050:
	case 11025:
		*clk_rate = 22579200;
		break;

	case 192000:
	case 128000:
	case 96000:
	case 64000:
	case 48000:
	case 32000:
	case 24000:
	case 16000:
	case 12000:
	case 8000:
		*clk_rate = 24576000;
		break;

	default:
		dev_err(i2s->dev, "Unsupported frame rate: %u\n",
			sample_rate);
		return -EINVAL;
	}

	ret = clk_set_rate(i2s->mod_clk, *clk_rate);
	if (ret) {
		dev_err(i2s->dev, "Unable to set PLL rate\n");
		return ret;
	}

	return 0;
}

static int sun4i_i2s_set_frame_period(struct sun4i_i2s *i2s, u32 channels,
				      u32 word_size)
{
	u32 bclk_ratio;
	int i, max = 4;

	if (i2s->bclk_ratio) {
		for (i = 0; i <= max; i++) {
			bclk_ratio = (1 << (4 + i));

			if (i2s->bclk_ratio < bclk_ratio) {
				i2s->bclk_ratio = bclk_ratio;
				break;
			} else if (i2s->bclk_ratio == bclk_ratio)
				break;
		}

		if (i2s->bclk_ratio > bclk_ratio) {
			i = max;
			i2s->bclk_ratio = bclk_ratio;
		}

		regmap_update_bits(i2s->regmap,
				   SUN4I_I2S_REG_FMT1,
				   SUN4I_I2S_FMT1_PCM_SYNC_PRD_MASK,
				   SUN4I_I2S_FMT1_PCM_SYNC_PRD(i));

		dev_dbg(i2s->dev, "%s: SYNC period = %d, BCLK ratio = %d\n",
			 __func__, i, i2s->bclk_ratio);
	} else {
		regmap_update_bits(i2s->regmap, SUN4I_I2S_REG_FMT1,
				   SUN4I_I2S_FMT1_PCM_SYNC_PRD_MASK,
				   SUN4I_I2S_FMT1_PCM_SYNC_PRD(max));
	}

	return 0;
}

static int sun8i_i2s_set_frame_period(struct sun4i_i2s *i2s, u32 channels,
				      u32 word_size)
{
	u32 lrck_period, min;

	if (i2s->is_pcm) {
		/* For PCM mode LRCK period includes both channels */
		min = word_size * channels;
		channels = 1;
	} else
		min = word_size;

	lrck_period = i2s->bclk_ratio / channels;
	if (lrck_period < min) {
		lrck_period = min;

	} else if (lrck_period > SUN8I_I2S_LRCK_MAX_PERIOD) {
		lrck_period = SUN8I_I2S_LRCK_MAX_PERIOD;
	}

	i2s->bclk_ratio = lrck_period * channels;

	/* Set LRCK(R) period */
	regmap_update_bits(i2s->regmap, SUN4I_I2S_REG_FMT0,
			   SUN8I_I2S_LRCK_PERIOD_MASK,
			   SUN8I_I2S_LRCK_PERIOD(lrck_period));

	regmap_update_bits(i2s->regmap, SUN4I_I2S_REG_FMT0,
			   SUN8I_I2S_LRCKR_PERIOD_MASK,
			   SUN8I_I2S_LRCKR_PERIOD(lrck_period));

	dev_dbg(i2s->dev,
		"%s: BCLK ratio = %d, LRCK period = %d\n",
                __func__, i2s->bclk_ratio, lrck_period);

	return 0;
}

static int sun4i_i2s_set_rate(struct sun4i_i2s *i2s, u32 channels,
			      u32 sample_rate, u32 word_size)
{
	int ret, i;
	int bclk_div, mclk_div;
	u32 pll_rate, oversample_rate;
	u32 bclk_rate;

	if (i2s->bit_clk_master) {
		/* CPU bit & frame clk master */
		ret = sun4i_i2s_setup_pll(i2s, sample_rate, &pll_rate);
		if (ret)
			return ret;

		oversample_rate = i2s->mclk_rate / sample_rate;
		if (!sun4i_i2s_is_oversample_valid(oversample_rate)) {
			dev_err(i2s->dev, "Unsupported oversample: %d\n",
				oversample_rate);
			return -EINVAL;
		}

		mclk_div = sun4i_i2s_get_mclk_div(i2s, pll_rate,
						i2s->quirks->mclk_div,
						i2s->quirks->num_mclkdiv);
		if (mclk_div < 0) {
			dev_err(i2s->dev, "Unsupported MCLK rate\n");
			return -EINVAL;
		}

		bclk_div = sun4i_i2s_get_bclk_div(i2s,
						i2s->quirks->bclk_parent
							== BCLK_PARENT_PLL ?
							pll_rate : i2s->mclk_rate,
						channels,
						sample_rate,
						word_size);
		if (bclk_div < 0) {
			dev_err(i2s->dev, "Unsupported BCLK divider\n");
			return -EINVAL;
		}

		bclk_rate = sample_rate * i2s->bclk_ratio;

		dev_dbg(i2s->dev,
                        "%s: channels = %d, rate = %d, word = %d, o/sample = %d, PLL = %d, MCLK = %lu, BCLK = %d, BCLK ratio = %d\n",
                        __func__, channels, sample_rate, word_size, oversample_rate,
			pll_rate, i2s->mclk_rate, bclk_rate, i2s->bclk_ratio);

		dev_dbg(i2s->dev,
			"%s: setting dividers: MCLK div = %d, BCLK div = %d\n",
			 __func__, mclk_div, bclk_div);

		sun4i_i2s_field_set(i2s, FIELD_BCLK_DIV, bclk_div);
		sun4i_i2s_field_set(i2s, FIELD_MCLK_DIV, mclk_div);
		sun4i_i2s_field_set(i2s, FIELD_MCLK_OUT_EN, 1);

	} else {
		/* CPU bit & frame clk slave */
	}

	return 0;
}

static int sun4i_i2s_set_format(struct sun4i_i2s *i2s, u32 fmt)
{
	u32 mode, subm = 0, val;
	u32 format = (fmt & SND_SOC_DAIFMT_FORMAT_MASK);
	u32 master = (fmt & SND_SOC_DAIFMT_MASTER_MASK);

	/* DAI Mode */
	switch (format) {
	case SND_SOC_DAIFMT_I2S:
		mode = SUN4I_I2S_CTRL_MODE_I2S;
		subm = SUN4I_I2S_FMT0_FMT_I2S;
		break;

	case SND_SOC_DAIFMT_LEFT_J:
		mode = SUN4I_I2S_CTRL_MODE_I2S;
		subm = SUN4I_I2S_FMT0_FMT_LEFT_J;
		break;

	case SND_SOC_DAIFMT_RIGHT_J:
		mode = SUN4I_I2S_CTRL_MODE_I2S;
		subm = SUN4I_I2S_FMT0_FMT_RIGHT_J;
		break;

	case SND_SOC_DAIFMT_DSP_A:
		mode = SUN4I_I2S_CTRL_MODE_PCM;
		subm = SUN4I_I2S_FMT0_DSP_MODE_A;
		break;

	case SND_SOC_DAIFMT_DSP_B:
		mode = SUN4I_I2S_CTRL_MODE_PCM;
		subm = SUN4I_I2S_FMT0_DSP_MODE_B;
		break;

	default:
		dev_err(i2s->dev, "Unsupported format: %d\n",
			format);
		return -EINVAL;
	}

	regmap_update_bits(i2s->regmap, SUN4I_I2S_REG_CTRL,
			   SUN4I_I2S_CTRL_MODE_MASK, mode);

	switch (mode) {
	case SUN4I_I2S_CTRL_MODE_I2S:
		regmap_update_bits(i2s->regmap, SUN4I_I2S_REG_FMT0,
				   SUN4I_I2S_FMT0_FMT_MASK, subm);
		break;

	case SUN4I_I2S_CTRL_MODE_PCM:
		/* Store PCM mode flag */
		i2s->is_pcm = 1;

		regmap_update_bits(i2s->regmap, SUN4I_I2S_REG_FMT0,
				   SUN4I_I2S_FMT0_DSP_MODE_MASK,
				   subm);

		/* Set short sync (one BCLK period)*/
		regmap_update_bits(i2s->regmap, SUN4I_I2S_REG_FMT1,
				   SUN4I_I2S_PCM_SYNC_WIDTH,
				   SUN4I_I2S_PCM_SYNC_SHORT);
		break;
	}


	/* DAI clock master masks */
	switch (master) {
	case SND_SOC_DAIFMT_CBS_CFS:
		/* BCLK and LRCK master */
		val = SUN4I_I2S_CTRL_MASTER;
		i2s->bit_clk_master = 1;
		break;
	case SND_SOC_DAIFMT_CBM_CFM:
		/* BCLK and LRCLK slave */
		val = SUN4I_I2S_CTRL_SLAVE;
		i2s->bit_clk_master = 0;
		break;
	default:
		dev_err(i2s->dev,
			"Unsupported master/slave option: %d\n",
			master);
		return -EINVAL;
	}

	regmap_update_bits(i2s->regmap, SUN4I_I2S_REG_CTRL,
			   SUN4I_I2S_CTRL_SLAVE_MASK, val);

	return 0;
}

static int sun8i_i2s_set_format(struct sun4i_i2s *i2s, u32 fmt)
{
	u32 mode, val, offset = 0;
	u32 format = (fmt & SND_SOC_DAIFMT_FORMAT_MASK);
	u32 master = (fmt & SND_SOC_DAIFMT_MASTER_MASK);

	/*
	 * The offset indicates that we're connected to an I2S device,
	 * however offset is only used on sun8i hardware. I2S shares
	 * the same setting with the LJ format.
	 */
	/* DAI Mode */
	switch (format) {
	case SND_SOC_DAIFMT_I2S:
		mode = SUN8I_I2S_CTRL_MODE_LEFT_J;
		offset = 1;
		break;
	case SND_SOC_DAIFMT_LEFT_J:
		mode = SUN8I_I2S_CTRL_MODE_LEFT_J;
		break;
	case SND_SOC_DAIFMT_RIGHT_J:
		mode = SUN8I_I2S_CTRL_MODE_RIGHT_J;
		break;
	case SND_SOC_DAIFMT_DSP_A:
		mode = SUN8I_I2S_CTRL_MODE_PCM;
		offset = 1;
		break;
	case SND_SOC_DAIFMT_DSP_B:
		mode = SUN8I_I2S_CTRL_MODE_PCM;
		break;
	default:
		dev_err(i2s->dev, "Unsupported format: %d\n",
			format);
		return -EINVAL;
	}

	regmap_update_bits(i2s->regmap, SUN4I_I2S_REG_CTRL,
			   SUN8I_I2S_CTRL_MODE_MASK, mode);

	/* BCLK offset determines submode (see datasheet)*/
	regmap_update_bits(i2s->regmap, SUN8I_I2S_REG_TX_CHAN_SEL,
			   SUN8I_I2S_TX_CHAN_SEL_OFFSET_MASK,
			   SUN8I_I2S_TX_CHAN_SEL_OFFSET(offset));

	if (mode == SUN8I_I2S_CTRL_MODE_PCM) {
		/* Store PCM mode flag */
		i2s->is_pcm = 1;

		/* Set short sync (1 BCLK period)*/
		regmap_update_bits(i2s->regmap, SUN4I_I2S_REG_FMT0,
				   SUN8I_I2S_PCM_SYNC_WIDTH,
				   SUN8I_I2S_PCM_SYNC_SHORT);
	}

	/*
	 * The newer i2s block does not have a slave select bit,
	 * instead the clk pins are configured as inputs.
	 */
	/* DAI clock master masks */
	switch (master) {
	case SND_SOC_DAIFMT_CBS_CFS:
		/* BCLK and LRCLK master */
		val = SUN8I_I2S_CTRL_BCLK_OUT |
		      SUN8I_I2S_CTRL_LRCK_OUT;
		i2s->bit_clk_master = 1;
		break;
	case SND_SOC_DAIFMT_CBM_CFM:
		/* BCLK and LRCLK slave */
		val = 0;
		i2s->bit_clk_master = 0;
		break;
	default:
		dev_err(i2s->dev,
			"Unsupported master/slave option: %d\n",
			master);
		return -EINVAL;
	}

	regmap_update_bits(i2s->regmap, SUN4I_I2S_REG_CTRL,
			   SUN8I_I2S_CTRL_BCLK_OUT |
			   SUN8I_I2S_CTRL_LRCK_OUT, val);

	return 0;
}

static int sun4i_i2s_set_hw_config(struct snd_soc_dai *dai,
				   u32 channels, u32 sample_rate,
				   u32 sample_size, u32 word_size)
{
	struct sun4i_i2s *i2s = snd_soc_dai_get_drvdata(dai);
	u32 sr, wss;
	int i;

	switch (sample_size) {
	case 16:
		sr = 0;
		wss = 0;
		break;
	case 20:
		sr = 1;
		wss = 1;
		break;
	case 24:
		sr = 2;
		wss = 2;
		break;
	default:
		dev_err(dai->dev, "Unsupported sample size: %d\n",
			sample_size);
		return -EINVAL;
	}

	if (word_size > sample_size) {
		switch (word_size) {
		case 16:
			break;
		case 20:
			wss = 1;
			break;
		case 24:
			wss = 2;
			break;
		case 32:
			wss = 3;
			break;
		default:
			dev_err(dai->dev, "Unsupported word size: %d\n",
				word_size);
			return -EINVAL;
		}
	}

	regmap_update_bits(i2s->regmap, SUN4I_I2S_REG_FMT0,
			   SUN4I_I2S_FMT0_SR_MASK,
			   SUN4I_I2S_FMT0_SR(sr));

	regmap_update_bits(i2s->regmap, SUN4I_I2S_REG_FMT0,
			   SUN4I_I2S_FMT0_WSS_MASK,
			   SUN4I_I2S_FMT0_WSS(wss));

	dev_dbg(dai->dev,
		"%s: channels = %d, rate = %d, sample = %d (sr = %d), word = %d (wss = %d)\n",
		__func__, channels, sample_rate, sample_size, sr, word_size, wss);

	return 0;
}

static int sun8i_i2s_set_hw_config(struct snd_soc_dai *dai,
				   u32 channels, u32 sample_rate,
				   u32 sample_size, u32 word_size)
{
	struct sun4i_i2s *i2s = snd_soc_dai_get_drvdata(dai);
	u32 sr, sw;

	/* Set channel config register */
       	regmap_update_bits(i2s->regmap, SUN8I_I2S_REG_CHAN_CFG,
			   SUN8I_I2S_CHAN_CFG_TX_SLOT_NUM_MASK,
			   SUN8I_I2S_CHAN_CFG_TX_SLOT_NUM(channels));

	regmap_update_bits(i2s->regmap, SUN8I_I2S_REG_CHAN_CFG,
			   SUN8I_I2S_CHAN_CFG_RX_SLOT_NUM_MASK,
			   SUN8I_I2S_CHAN_CFG_RX_SLOT_NUM(channels));

	/* Enable TX channels */
	regmap_update_bits(i2s->regmap, SUN8I_I2S_REG_TX_CHAN_SEL,
			   SUN8I_I2S_TX_CHAN_SEL_EN_MASK,
			   SUN8I_I2S_TX_CHAN_SEL_EN(channels));

	switch (sample_size) {
	case 16:
		sr = 3;
		sw = 3;
		break;
	case 20:
		sr = 4;
		sw = 4;
		break;
	case 24:
		sr = 5;
		sw = 5;
		break;
	case 32:
		sr = 7;
		sw = 7;
		break;
        default:
		dev_err(i2s->dev, "Unsupported sample size: %d\n",
			sample_size);
		return -EINVAL;
	}

	if (word_size > sample_size) {
		switch (word_size) {
		case 16:
			break;
		case 20:
			sw = 4;
			break;
		case 24:
			sw = 5;
			break;
		case 32:
			sw = 7;
			break;
		default:
			dev_err(dai->dev, "Unsupported word size: %d\n",
				word_size);
			return -EINVAL;
		}
	}

	regmap_update_bits(i2s->regmap, SUN4I_I2S_REG_FMT0,
			   SUN8I_I2S_FMT0_SR_MASK,
			   SUN8I_I2S_FMT0_SR(sr));

	regmap_update_bits(i2s->regmap, SUN4I_I2S_REG_FMT0,
			   SUN8I_I2S_FMT0_SW_MASK,
			   SUN8I_I2S_FMT0_SW(sw));

        dev_dbg(dai->dev,
                "%s: channels = %d, rate = %d, sample = %d (sr = %d), word = %d (sw = %d)\n",
                __func__, channels, sample_rate, sample_size, sr, word_size, sw);

	return 0;
}

#define FULL_CHAN_MAP	SUN4I_I2S_CHAN_MAP(0,0) | \
			SUN4I_I2S_CHAN_MAP(1,1) | \
			SUN4I_I2S_CHAN_MAP(2,2) | \
			SUN4I_I2S_CHAN_MAP(3,3) | \
			SUN4I_I2S_CHAN_MAP(4,4) | \
			SUN4I_I2S_CHAN_MAP(5,5) | \
			SUN4I_I2S_CHAN_MAP(6,6) | \
			SUN4I_I2S_CHAN_MAP(7,7)

static int sun4i_i2s_hw_params(struct snd_pcm_substream *substream,
			       struct snd_pcm_hw_params *params,
			       struct snd_soc_dai *dai)
{
	struct sun4i_i2s *i2s = snd_soc_dai_get_drvdata(dai);
	u32 channels, lines;
	u32 bus_width, sample_rate;
	u32 word_size;
	u32 sample_size, storage_size;
	int ret;

	channels	= params_channels(params);
	sample_size	= params_width(params);
	sample_rate	= params_rate(params);
	storage_size	= params_physical_width(params);

	if ((channels > dai->driver->playback.channels_max) ||
	    (channels < dai->driver->playback.channels_min)) {
		dev_err(dai->dev, "Unsupported number of channels: %d\n",
			channels);
		return -EINVAL;
	}

	lines = (channels + 1) / 2;

	/* Enable the required output lines */
	regmap_update_bits(i2s->regmap, SUN4I_I2S_REG_CTRL,
			   SUN4I_I2S_CTRL_SDO_EN_MASK,
			   SUN4I_I2S_CTRL_SDO_EN(lines));

	switch (storage_size) {
	case 16:
		bus_width = DMA_SLAVE_BUSWIDTH_2_BYTES;
		break;
	case 24:
	case 32:
		bus_width = DMA_SLAVE_BUSWIDTH_4_BYTES;
		break;
	default:
		dev_err(i2s->dev, "Unsupported storage size: %d\n",
			storage_size);
		return -EINVAL;
	}
	i2s->dma_data[SNDRV_PCM_STREAM_PLAYBACK].addr_width = bus_width;
	i2s->dma_data[SNDRV_PCM_STREAM_CAPTURE].addr_width = bus_width;


	/* Map channels for playback */
	sun4i_i2s_field_set(i2s, FIELD_TX_CHAN_MAP, FULL_CHAN_MAP);

	/* Select playback channels */
	sun4i_i2s_field_set(i2s, FIELD_TX_CHAN_SEL,
			    SUN4I_I2S_CHAN_SEL(channels));

	/* Map channels for capture */
	sun4i_i2s_field_set(i2s, FIELD_RX_CHAN_MAP, FULL_CHAN_MAP);

	/* Select capture channels */
	sun4i_i2s_field_set(i2s, FIELD_RX_CHAN_SEL,
			    SUN4I_I2S_CHAN_SEL(channels));

	if (i2s->slot_width)
		/* Override the word size from device tree */
		word_size = i2s->slot_width;
	else {
		switch (sample_size) {
		case 32:
		case 24:
		case 20:
			/* Always use 32-bit slot if samples > 16 */
			word_size = 32;
			break;
		case 16:
			word_size = 16;
			break;
		default:
			dev_err(i2s->dev, "Unsupported sample size: %d\n",
				sample_size);
			return -EINVAL;
		}
	}

	ret = i2s->quirks->set_frame_period(i2s, channels, word_size);
	if (ret)
		return ret;

	ret = sun4i_i2s_set_rate(i2s, channels, sample_rate, word_size);
	if (ret)
		return ret;

	/* Invoke platform-specific hardware config */
	ret = i2s->quirks->set_hw_config(dai, channels, sample_rate,
					 sample_size, word_size);
	if (ret)
		return ret;

	/* Set to pad out LSB with 0 */
	sun4i_i2s_field_set(i2s, FIELD_SIGN_EXT, 0);

	return 0;
}

static int sun4i_i2s_set_fmt(struct snd_soc_dai *dai, unsigned int fmt)
{
	struct sun4i_i2s *i2s = snd_soc_dai_get_drvdata(dai);
	u32 bclk_pol = SUN4I_I2S_POLARITY_NORMAL;
	u32 lrck_pol = SUN4I_I2S_POLARITY_NORMAL;
	int ret;

	/* Invoke platform-specific portion */
	ret = i2s->quirks->set_format(i2s, fmt);
	if (ret)
		return ret;

        /* DAI clock polarity */
        switch (fmt & SND_SOC_DAIFMT_INV_MASK) {
        case SND_SOC_DAIFMT_IB_IF:
                /* Invert both clocks */
                bclk_pol = SUN4I_I2S_POLARITY_INVERT;
                lrck_pol = SUN4I_I2S_POLARITY_INVERT;
                break;
        case SND_SOC_DAIFMT_IB_NF:
                /* Invert bit clock only */
                bclk_pol = SUN4I_I2S_POLARITY_INVERT;
                break;
        case SND_SOC_DAIFMT_NB_IF:
                /* Invert frame clock only */
                lrck_pol = SUN4I_I2S_POLARITY_INVERT;
                break;
        case SND_SOC_DAIFMT_NB_NF:
                break;
        default:
                dev_err(i2s->dev, "Unsupported clock polarity: %d\n",
                        (fmt & SND_SOC_DAIFMT_INV_MASK));
                return -EINVAL;
        }

        sun4i_i2s_field_set(i2s, FIELD_BCLK_POLARITY, bclk_pol);

        /* LRCK can't be inverted in PCM mode */
        if (!i2s->is_pcm)
                sun4i_i2s_field_set(i2s, FIELD_LRCK_POLARITY, lrck_pol);
	else
		sun4i_i2s_field_set(i2s, FIELD_LRCK_POLARITY,
				    SUN4I_I2S_POLARITY_NORMAL);


	/* Set significant bits in FIFOs */
	regmap_update_bits(i2s->regmap, SUN4I_I2S_REG_FIFO_CTRL,
			   SUN4I_I2S_FIFO_CTRL_TX_IM_MASK |
			   SUN4I_I2S_FIFO_CTRL_RX_OM_MASK,
			   SUN4I_I2S_FIFO_CTRL_TX_IM(1) |
			   SUN4I_I2S_FIFO_CTRL_RX_OM(1));

	/* Try to avoid FIFO underrun */
	regmap_update_bits(i2s->regmap, SUN4I_I2S_REG_FIFO_CTRL,
			   SUN4I_I2S_FIFO_TX_TL_MASK,
			   SUN4I_I2S_FIFO_TX_TL(0x20));
	return 0;
}

/**
 * sun4i_i2s_set_bclk_ratio - configure BCLK to sample rate ratio.
 * @dai: DAI
 * @ratio: Ratio of BCLK to Sample rate.
 *
 * Configures the DAI for a preset BCLK to sample rate ratio.
 */
static int sun4i_i2s_set_bclk_ratio(struct snd_soc_dai *dai,
				    unsigned int ratio)
{
	struct sun4i_i2s *i2s = snd_soc_dai_get_drvdata(dai);

	i2s->bclk_ratio = ratio;

	return 0;
}

static int sun4i_i2s_set_sysclk(struct snd_soc_dai *dai, int clk_id,
				unsigned int rate, int dir)
{
	struct sun4i_i2s *i2s = snd_soc_dai_get_drvdata(dai);

	if (clk_id != 0)
		return -EINVAL;

	i2s->mclk_rate = rate;

	return 0;
}

static void sun4i_i2s_shutdown(struct snd_pcm_substream *substream,
			       struct snd_soc_dai *dai)
{
	struct sun4i_i2s *i2s = snd_soc_dai_get_drvdata(dai);

	clk_disable_unprepare(i2s->mod_clk);

	/* Disable output lines */
	regmap_update_bits(i2s->regmap, SUN4I_I2S_REG_CTRL,
			   SUN4I_I2S_CTRL_SDO_EN_MASK, 0);

	/* Disable whole hardware block */
	regmap_update_bits(i2s->regmap, SUN4I_I2S_REG_CTRL,
			   SUN4I_I2S_CTRL_GLOB_EN, 0);

	/* Reset BCLK ratio */
	i2s->bclk_ratio = 0;
}

static int sun4i_i2s_startup(struct snd_pcm_substream *substream,
			     struct snd_soc_dai *dai)
{
	struct sun4i_i2s *i2s = snd_soc_dai_get_drvdata(dai);

	/* Enable whole hardware block */
	regmap_update_bits(i2s->regmap, SUN4I_I2S_REG_CTRL,
			   SUN4I_I2S_CTRL_GLOB_EN,
			   SUN4I_I2S_CTRL_GLOB_EN);

	return clk_prepare_enable(i2s->mod_clk);
}

static void sun4i_i2s_start_playback(struct sun4i_i2s *i2s)
{
	/* Flush TX FIFO */
	regmap_update_bits(i2s->regmap,
			   SUN4I_I2S_REG_FIFO_CTRL,
			   SUN4I_I2S_FIFO_FLUSH_TX,
			   SUN4I_I2S_FIFO_FLUSH_TX);

	/* Clear TX counter */
	regmap_write(i2s->regmap, SUN4I_I2S_REG_TX_COUNT, 0);


	/* Enable TX Block */
	regmap_update_bits(i2s->regmap, SUN4I_I2S_REG_CTRL,
			   SUN4I_I2S_CTRL_TX_EN,
			   SUN4I_I2S_CTRL_TX_EN);

	/* Enable TX DRQ */
	regmap_update_bits(i2s->regmap,
			   SUN4I_I2S_REG_DMA_INT_CTRL,
			   SUN4I_I2S_TX_DRQ_EN,
			   SUN4I_I2S_TX_DRQ_EN);

}

static void sun4i_i2s_start_capture(struct sun4i_i2s *i2s)
{
	/* Flush RX FIFO */
	regmap_update_bits(i2s->regmap,
			   SUN4I_I2S_REG_FIFO_CTRL,
			   SUN4I_I2S_FIFO_FLUSH_RX,
			   SUN4I_I2S_FIFO_FLUSH_RX);

	/* Clear RX counter */
	regmap_write(i2s->regmap, SUN4I_I2S_REG_RX_COUNT, 0);


	/* Enable RX Block */
	regmap_update_bits(i2s->regmap, SUN4I_I2S_REG_CTRL,
			   SUN4I_I2S_CTRL_RX_EN,
			   SUN4I_I2S_CTRL_RX_EN);

	/* Enable RX DRQ */
	regmap_update_bits(i2s->regmap,
			   SUN4I_I2S_REG_DMA_INT_CTRL,
			   SUN4I_I2S_RX_DRQ_EN,
			   SUN4I_I2S_RX_DRQ_EN);

	/* Debugging without codec */
	if (i2s->loopback)
		regmap_update_bits(i2s->regmap,
				   SUN4I_I2S_REG_CTRL,
				   SUN4I_I2S_CTRL_LOOPBACK,
				   SUN4I_I2S_CTRL_LOOPBACK);
}

static void sun4i_i2s_stop_capture(struct sun4i_i2s *i2s)
{
	/* Disable RX Block */
	regmap_update_bits(i2s->regmap, SUN4I_I2S_REG_CTRL,
			   SUN4I_I2S_CTRL_RX_EN, 0);

	/* Disable RX DRQ */
	regmap_update_bits(i2s->regmap,
			   SUN4I_I2S_REG_DMA_INT_CTRL,
			   SUN4I_I2S_RX_DRQ_EN, 0);
}

static void sun4i_i2s_stop_playback(struct sun4i_i2s *i2s)
{
	/* Disable TX Block */
	regmap_update_bits(i2s->regmap, SUN4I_I2S_REG_CTRL,
			   SUN4I_I2S_CTRL_TX_EN, 0);

	/* Disable TX DRQ */
	regmap_update_bits(i2s->regmap,
			   SUN4I_I2S_REG_DMA_INT_CTRL,
			   SUN4I_I2S_TX_DRQ_EN, 0);
}

static int sun4i_i2s_trigger(struct snd_pcm_substream *substream,
			     int cmd, struct snd_soc_dai *dai)
{
	struct sun4i_i2s *i2s = snd_soc_dai_get_drvdata(dai);

	switch (cmd) {
	case SNDRV_PCM_TRIGGER_START:
	case SNDRV_PCM_TRIGGER_PAUSE_RELEASE:
	case SNDRV_PCM_TRIGGER_RESUME:
		if (substream->stream == SNDRV_PCM_STREAM_PLAYBACK)
			sun4i_i2s_start_playback(i2s);
		else
			sun4i_i2s_start_capture(i2s);
		break;

	case SNDRV_PCM_TRIGGER_STOP:
	case SNDRV_PCM_TRIGGER_PAUSE_PUSH:
	case SNDRV_PCM_TRIGGER_SUSPEND:
		if (substream->stream == SNDRV_PCM_STREAM_PLAYBACK)
			sun4i_i2s_stop_playback(i2s);
		else
			sun4i_i2s_stop_capture(i2s);
		break;

	default:
		return -EINVAL;
	}

	return 0;
}

static const struct snd_soc_dai_ops sun4i_i2s_dai_ops = {
	.hw_params	= sun4i_i2s_hw_params,
	.set_fmt	= sun4i_i2s_set_fmt,
	.set_bclk_ratio = sun4i_i2s_set_bclk_ratio,
	.set_sysclk	= sun4i_i2s_set_sysclk,
	.shutdown	= sun4i_i2s_shutdown,
	.startup	= sun4i_i2s_startup,
	.trigger	= sun4i_i2s_trigger,
};

static int sun4i_i2s_dai_probe(struct snd_soc_dai *dai)
{
	struct sun4i_i2s *i2s = snd_soc_dai_get_drvdata(dai);

	snd_soc_dai_init_dma_data(dai,
			&i2s->dma_data[SNDRV_PCM_STREAM_PLAYBACK],
			&i2s->dma_data[SNDRV_PCM_STREAM_CAPTURE]);

	snd_soc_dai_set_drvdata(dai, i2s);

	return 0;
}

static struct snd_soc_dai_driver sun4i_i2s_dai = {
	.probe	= sun4i_i2s_dai_probe,
	.capture = {
		.stream_name = "Capture",
		.channels_min = 2,
		.channels_max = 2,
		.rates = SNDRV_PCM_RATE_8000_192000,
	},
	.playback = {
		.stream_name = "Playback",
		.channels_min = 2,
		.channels_max = 2,
		.rates = SNDRV_PCM_RATE_8000_192000,
	},
	.ops = &sun4i_i2s_dai_ops,
	.symmetric_rates = 1,
};

static const struct snd_soc_component_driver sun4i_i2s_component = {
	.name	= "sun4i-dai",
};


static int sun4i_i2s_alloc_regmap_fields(struct device *dev,
					 struct sun4i_i2s *i2s)
{
	int i, ret;

	for (i = 0; i < REGMAP_NUM_FIELDS; i++) {
		i2s->fields[i] = devm_regmap_field_alloc(dev,
						i2s->regmap,
						i2s->quirks->reg_fields[i]);
		if (IS_ERR(i2s->fields[i])) {
			dev_err(dev, "Failed to allocate regmap field\n");
			ret = PTR_ERR(i2s->fields[i]);
			i2s->fields[i] = NULL;
			return ret;
		}
	}

	return 0;
}

static int sun4i_i2s_runtime_resume(struct device *dev)
{
	struct sun4i_i2s *i2s = dev_get_drvdata(dev);
	int ret;

	ret = clk_prepare_enable(i2s->bus_clk);
	if (ret) {
		dev_err(dev, "Failed to enable bus clock\n");
		return ret;
	}

	regcache_cache_only(i2s->regmap, false);
	regcache_mark_dirty(i2s->regmap);

	ret = regcache_sync(i2s->regmap);
	if (ret) {
		dev_err(dev, "Failed to sync regmap cache\n");
		goto err_disable_clk;
	}

	return 0;

err_disable_clk:
	clk_disable_unprepare(i2s->bus_clk);

	return ret;
}

static int sun4i_i2s_runtime_suspend(struct device *dev)
{
	struct sun4i_i2s *i2s = dev_get_drvdata(dev);

	regcache_cache_only(i2s->regmap, true);

	clk_disable_unprepare(i2s->bus_clk);

	return 0;
}

static int sun4i_i2s_probe(struct platform_device *pdev)
{
	struct device *dev = &pdev->dev;
	struct sun4i_i2s *i2s;
	struct snd_soc_dai_driver *soc_dai;
	struct resource *res;
	void __iomem *base;
	u32 val;
	int irq, ret;

	i2s = devm_kzalloc(dev, sizeof(*i2s), GFP_KERNEL);
	if (!i2s)
		return -ENOMEM;

	i2s->dev = dev;
	platform_set_drvdata(pdev, i2s);

	res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	base = devm_ioremap_resource(dev, res);
	if (IS_ERR(base))
		return PTR_ERR(base);

	irq = platform_get_irq(pdev, 0);
	if (irq < 0) {
		dev_err(dev, "Couldn't request interrupt\n");
		return irq;
        }

	i2s->quirks = of_device_get_match_data(dev);
	if (!i2s->quirks) {
		dev_err(dev, "Failed to get quirks to use\n");
		return -ENODEV;
	}

	i2s->regmap = devm_regmap_init_mmio(dev, base,
					i2s->quirks->regmap_cfg);
	if (IS_ERR(i2s->regmap)) {
		dev_err(dev, "Couldn't initialize regmap\n");
		return PTR_ERR(i2s->regmap);
	}

	i2s->bus_clk = devm_clk_get(dev, "apb");
	if (IS_ERR(i2s->bus_clk)) {
		dev_err(dev, "Couldn't get bus clock\n");
		return PTR_ERR(i2s->bus_clk);
	}

	i2s->mod_clk = devm_clk_get(dev, "mod");
	if (IS_ERR(i2s->mod_clk)) {
		dev_err(dev, "Couldn't get mod clock\n");
		return PTR_ERR(i2s->mod_clk);
	}

	if (i2s->quirks->has_reset) {
		i2s->rst = devm_reset_control_get_exclusive(
					dev, NULL);
		if (IS_ERR(i2s->rst)) {
			dev_err(dev, "Failed to get reset control\n");
			return PTR_ERR(i2s->rst);
		}
	}

	if (!IS_ERR(i2s->rst)) {
		ret = reset_control_deassert(i2s->rst);
		if (ret) {
			dev_err(dev,
				"Couldn't deassert reset control\n");
			return -EINVAL;
		}
	}

	i2s->dma_data[SNDRV_PCM_STREAM_PLAYBACK].addr = res->start +
						i2s->quirks->reg_offset_txdata;
	i2s->dma_data[SNDRV_PCM_STREAM_CAPTURE].addr = res->start +
						SUN4I_I2S_REG_RX_FIFO;

	i2s->dma_data[SNDRV_PCM_STREAM_PLAYBACK].maxburst = 8;
	i2s->dma_data[SNDRV_PCM_STREAM_CAPTURE].maxburst = 8;


	if (of_property_read_bool(dev->of_node, "loopback"))
		i2s->loopback = 1;

	if (!of_property_read_u32(dev->of_node,
			"allwinner,slot-width-override", &val)) {
		if (val >= 16 && val <= 32)
			i2s->slot_width = val;
	}

	soc_dai = devm_kmemdup(dev, &sun4i_i2s_dai,
			       sizeof(*soc_dai), GFP_KERNEL);
	if (!soc_dai)
		goto err_quit;

	soc_dai->playback.formats = i2s->quirks->playback_formats;
	soc_dai->capture.formats = i2s->quirks->capture_formats;

	ret = sun4i_i2s_alloc_regmap_fields(dev, i2s);
	if (ret) {
		dev_err(dev, "Couldn't alloc regmap fields: %d\n",
			ret);
		goto err_quit;
	}

	ret = sun4i_i2s_runtime_resume(dev);
	if (ret) {
		dev_err(dev, "Couldn't resume device: %d\n", ret);
		goto err_quit;
	}

	pm_runtime_set_active(dev);
	pm_runtime_enable(dev);
	pm_runtime_idle(dev);

	ret = devm_snd_soc_register_component(dev,
					      &sun4i_i2s_component,
					      soc_dai, 1);
	if (ret) {
		dev_err(dev, "Could not register DAI: %d\n", ret);
		goto err_pm_disable;
	}

	ret = snd_dmaengine_pcm_register(dev, NULL, 0);
	if (ret) {
		dev_err(dev, "Could not register PCM: %d\n", ret);
		goto err_pm_disable;
	}

	return 0;

err_pm_disable:
	pm_runtime_disable(dev);

	if (!pm_runtime_status_suspended(dev))
		sun4i_i2s_runtime_suspend(dev);
err_quit:
	if (!IS_ERR(i2s->rst))
		reset_control_assert(i2s->rst);

	return ret;
}

static int sun4i_i2s_remove(struct platform_device *pdev)
{
	struct sun4i_i2s *i2s = dev_get_drvdata(&pdev->dev);

	snd_dmaengine_pcm_unregister(&pdev->dev);

	pm_runtime_force_suspend(&pdev->dev);

	if (!IS_ERR(i2s->rst))
		reset_control_assert(i2s->rst);

	return 0;
}

static bool sun4i_i2s_readable_reg(struct device *dev, u32 reg)
{
	switch (reg) {
	case SUN4I_I2S_REG_TX_FIFO:
		return false;

	default:
		return true;
	}
}

static bool sun4i_i2s_writable_reg(struct device *dev, u32 reg)
{
	switch (reg) {
	case SUN4I_I2S_REG_RX_FIFO:
	case SUN4I_I2S_REG_FIFO_STA:
		return false;

	default:
		return true;
	}
}

static bool sun4i_i2s_volatile_reg(struct device *dev, u32 reg)
{
	switch (reg) {
	case SUN4I_I2S_REG_RX_FIFO:
	case SUN4I_I2S_REG_INT_STA:
	case SUN4I_I2S_REG_RX_COUNT:
	case SUN4I_I2S_REG_TX_COUNT:
		return true;

	default:
		return false;
	}
}

static bool sun8i_i2s_readable_reg(struct device *dev, u32 reg)
{
	switch (reg) {
	case SUN8I_I2S_REG_TX_FIFO:
		return false;

	default:
		return true;
	}
}

static bool sun8i_i2s_volatile_reg(struct device *dev, u32 reg)
{
	switch (reg) {
	case SUN8I_I2S_REG_INT_STA:
		return true;
	case SUN8I_I2S_REG_TX_FIFO:
		return false;

	default:
		return sun4i_i2s_volatile_reg(dev, reg);
	}
}

static const struct reg_default sun4i_i2s_reg_defaults[] = {
	{ SUN4I_I2S_REG_CTRL,		0x00000000 },
	{ SUN4I_I2S_REG_FMT0,		0x0000000c },
	{ SUN4I_I2S_REG_FMT1,		0x00004020 },
	{ SUN4I_I2S_REG_FIFO_CTRL,	0x000400f0 },
	{ SUN4I_I2S_REG_DMA_INT_CTRL,	0x00000000 },
	{ SUN4I_I2S_REG_CLKDIV,		0x00000000 },
	{ SUN4I_I2S_REG_TX_CHAN_SEL,	0x00000001 },
	{ SUN4I_I2S_REG_TX_CHAN_MAP,	0x76543210 },
	{ SUN4I_I2S_REG_RX_CHAN_SEL,	0x00000001 },
	{ SUN4I_I2S_REG_RX_CHAN_MAP,	0x00003210 },
};

static const struct reg_default sun8i_i2s_reg_defaults[] = {
	{ SUN4I_I2S_REG_CTRL,		0x00060000 },
	{ SUN4I_I2S_REG_FMT0,		0x00000033 },
	{ SUN4I_I2S_REG_FMT1,		0x00000030 },
	{ SUN4I_I2S_REG_FIFO_CTRL,	0x000400f0 },
	{ SUN4I_I2S_REG_DMA_INT_CTRL,	0x00000000 },
	{ SUN4I_I2S_REG_CLKDIV,		0x00000000 },
	{ SUN8I_I2S_REG_CHAN_CFG,	0x00000000 },
	{ SUN8I_I2S_REG_TX_CHAN_SEL,	0x00000000 },
	{ SUN8I_I2S_REG_TX_CHAN_MAP,	0x00000000 },
	{ SUN8I_I2S_REG_RX_CHAN_SEL,	0x00000000 },
	{ SUN8I_I2S_REG_RX_CHAN_MAP,	0x00000000 },
};

static const struct regmap_config sun4i_i2s_regmap_config = {
	.reg_bits		= 32,
	.reg_stride		= 4,
	.val_bits		= 32,
	.max_register		= SUN4I_I2S_REG_RX_CHAN_MAP,
	.cache_type		= REGCACHE_FLAT,
	.reg_defaults		= sun4i_i2s_reg_defaults,
	.num_reg_defaults	= ARRAY_SIZE(sun4i_i2s_reg_defaults),
	.writeable_reg		= sun4i_i2s_writable_reg,
	.readable_reg		= sun4i_i2s_readable_reg,
	.volatile_reg		= sun4i_i2s_volatile_reg,
};

static const struct regmap_config sun8i_i2s_regmap_config = {
	.reg_bits		= 32,
	.reg_stride		= 4,
	.val_bits		= 32,
	.max_register		= SUN8I_I2S_REG_RX_CHAN_MAP,
	.cache_type		= REGCACHE_FLAT,
	.reg_defaults		= sun8i_i2s_reg_defaults,
	.num_reg_defaults	= ARRAY_SIZE(sun8i_i2s_reg_defaults),
	.writeable_reg		= sun4i_i2s_writable_reg,
	.readable_reg		= sun8i_i2s_readable_reg,
	.volatile_reg		= sun8i_i2s_volatile_reg,
};

static const struct reg_field sun4i_a10_i2s_reg_fields[REGMAP_NUM_FIELDS] = {
	[FIELD_MCLK_OUT_EN]	= REG_FIELD(SUN4I_I2S_REG_CLKDIV, 7, 7),
	[FIELD_BCLK_DIV]	= REG_FIELD(SUN4I_I2S_REG_CLKDIV, 4, 6),
	[FIELD_MCLK_DIV]	= REG_FIELD(SUN4I_I2S_REG_CLKDIV, 0, 3),
	[FIELD_BCLK_POLARITY]	= REG_FIELD(SUN4I_I2S_REG_FMT0, 6, 6),
	[FIELD_LRCK_POLARITY]	= REG_FIELD(SUN4I_I2S_REG_FMT0, 7, 7),
	[FIELD_SIGN_EXT]	= REG_FIELD(SUN4I_I2S_REG_FMT1, 8, 8),
	[FIELD_TX_CHAN_SEL]	= REG_FIELD(SUN4I_I2S_REG_TX_CHAN_SEL, 0, 2),
	[FIELD_RX_CHAN_SEL]	= REG_FIELD(SUN4I_I2S_REG_RX_CHAN_SEL, 0, 2),
	[FIELD_TX_CHAN_MAP]	= REG_FIELD(SUN4I_I2S_REG_TX_CHAN_MAP, 0, 31),
	[FIELD_RX_CHAN_MAP]	= REG_FIELD(SUN4I_I2S_REG_RX_CHAN_MAP, 0, 31),
};

static const struct reg_field sun8i_h3_i2s_reg_fields[REGMAP_NUM_FIELDS] = {
	[FIELD_MCLK_OUT_EN]	= REG_FIELD(SUN4I_I2S_REG_CLKDIV, 8, 8),
	[FIELD_BCLK_DIV]	= REG_FIELD(SUN4I_I2S_REG_CLKDIV, 4, 7),
	[FIELD_MCLK_DIV]	= REG_FIELD(SUN4I_I2S_REG_CLKDIV, 0, 3),
	[FIELD_BCLK_POLARITY]	= REG_FIELD(SUN4I_I2S_REG_FMT0, 7, 7),
	[FIELD_LRCK_POLARITY]	= REG_FIELD(SUN4I_I2S_REG_FMT0, 19, 19),
	[FIELD_SIGN_EXT]	= REG_FIELD(SUN4I_I2S_REG_FMT1, 4, 5),
	[FIELD_TX_CHAN_SEL]	= REG_FIELD(SUN8I_I2S_REG_TX_CHAN_SEL, 0, 2),
	[FIELD_RX_CHAN_SEL]	= REG_FIELD(SUN8I_I2S_REG_RX_CHAN_SEL, 0, 2),
	[FIELD_TX_CHAN_MAP]	= REG_FIELD(SUN8I_I2S_REG_TX_CHAN_MAP, 0, 31),
	[FIELD_RX_CHAN_MAP]	= REG_FIELD(SUN8I_I2S_REG_RX_CHAN_MAP, 0, 31),
};

#define SUN4I_FORMATS	(SNDRV_PCM_FMTBIT_S16_LE | \
			 SNDRV_PCM_FMTBIT_S24_LE)

#define SUN8I_FORMATS	(SUN4I_FORMATS | \
			 SNDRV_PCM_FMTBIT_S32_LE)

static struct sun4i_i2s_quirks sun4i_a10_i2s_quirks = {
	.has_reset		= 0,
	.reg_offset_txdata	= SUN4I_I2S_REG_TX_FIFO,
	.regmap_cfg		= &sun4i_i2s_regmap_config,
	.reg_fields		= sun4i_a10_i2s_reg_fields,

	.bclk_div		= sun4i_i2s_bclk_div,
	.num_bclkdiv		= ARRAY_SIZE(sun4i_i2s_bclk_div),
	.mclk_div		= sun4i_i2s_mclk_div,
	.num_mclkdiv		= ARRAY_SIZE(sun4i_i2s_mclk_div),

	.playback_formats	= SUN4I_FORMATS,
	.capture_formats	= SUN4I_FORMATS,

	/* DAI configuration callbacks */
	.set_format		= sun4i_i2s_set_format,
	.set_hw_config		= sun4i_i2s_set_hw_config,
	.set_frame_period	= sun4i_i2s_set_frame_period,
};

static const struct sun4i_i2s_quirks sun6i_a31_i2s_quirks = {
	.has_reset		= 1,
	.reg_offset_txdata	= SUN4I_I2S_REG_TX_FIFO,
	.regmap_cfg		= &sun4i_i2s_regmap_config,
	.reg_fields		= sun4i_a10_i2s_reg_fields,

	.bclk_div		= sun4i_i2s_bclk_div,
	.num_bclkdiv		= ARRAY_SIZE(sun4i_i2s_bclk_div),
	.mclk_div		= sun4i_i2s_mclk_div,
	.num_mclkdiv		= ARRAY_SIZE(sun4i_i2s_mclk_div),

	.playback_formats	= SUN4I_FORMATS,
	.capture_formats	= SUN4I_FORMATS,

	/* DAI configuration callbacks */
	.set_format		= sun4i_i2s_set_format,
	.set_hw_config		= sun4i_i2s_set_hw_config,
	.set_frame_period	= sun4i_i2s_set_frame_period,
};

static const struct sun4i_i2s_quirks sun8i_a83t_i2s_quirks = {
	.has_reset		= 1,
	.reg_offset_txdata	= SUN8I_I2S_REG_TX_FIFO,
	.regmap_cfg		= &sun4i_i2s_regmap_config,
	.reg_fields		= sun4i_a10_i2s_reg_fields,

	.bclk_div		= sun4i_i2s_bclk_div,
	.num_bclkdiv		= ARRAY_SIZE(sun4i_i2s_bclk_div),
	.mclk_div		= sun4i_i2s_mclk_div,
	.num_mclkdiv		= ARRAY_SIZE(sun4i_i2s_mclk_div),

	.playback_formats	= SUN4I_FORMATS,
	.capture_formats	= SUN4I_FORMATS,

	/* DAI configuration callbacks */
	.set_format		= sun4i_i2s_set_format,
	.set_hw_config		= sun4i_i2s_set_hw_config,
	.set_frame_period	= sun4i_i2s_set_frame_period,
};

static struct sun4i_i2s_quirks sun8i_h3_i2s_quirks = {
	.has_reset		= 1,
	.reg_offset_txdata	= SUN8I_I2S_REG_TX_FIFO,
	.regmap_cfg		= &sun8i_i2s_regmap_config,
	.reg_fields		= sun8i_h3_i2s_reg_fields,

	.bclk_div		= sun8i_i2s_clk_div,
	.num_bclkdiv		= ARRAY_SIZE(sun8i_i2s_clk_div),
	.mclk_div		= sun8i_i2s_clk_div,
	.num_mclkdiv		= ARRAY_SIZE(sun8i_i2s_clk_div),

	.bclk_parent		= BCLK_PARENT_PLL,

	.playback_formats	= SUN8I_FORMATS,
	.capture_formats	= SUN8I_FORMATS,

	/* DAI configuration callbacks */
	.set_format		= sun8i_i2s_set_format,
	.set_hw_config		= sun8i_i2s_set_hw_config,
	.set_frame_period	= sun8i_i2s_set_frame_period,
};

static const struct sun4i_i2s_quirks sun50i_a64_i2s_ap_quirks = {
	.has_reset		= 1,
	.reg_offset_txdata	= SUN8I_I2S_REG_TX_FIFO,
	.regmap_cfg		= &sun4i_i2s_regmap_config,
	.reg_fields		= sun4i_a10_i2s_reg_fields,

	.bclk_div		= sun4i_i2s_bclk_div,
	.num_bclkdiv		= ARRAY_SIZE(sun4i_i2s_bclk_div),
	.mclk_div		= sun4i_i2s_mclk_div,
	.num_mclkdiv		= ARRAY_SIZE(sun4i_i2s_mclk_div),

	.playback_formats	= SUN4I_FORMATS,
	.capture_formats	= SUN4I_FORMATS,

	/* DAI configuration callbacks */
	.set_format		= sun4i_i2s_set_format,
	.set_hw_config		= sun4i_i2s_set_hw_config,
	.set_frame_period	= sun4i_i2s_set_frame_period,
};

static const struct of_device_id sun4i_i2s_match[] = {
	{
		.compatible = "allwinner,sun4i-a10-i2s",
		.data = &sun4i_a10_i2s_quirks,
	},
	{
		.compatible = "allwinner,sun6i-a31-i2s",
		.data = &sun6i_a31_i2s_quirks,
	},
	{
		.compatible = "allwinner,sun8i-a83t-i2s",
		.data = &sun8i_a83t_i2s_quirks,
	},
	{
		.compatible = "allwinner,sun8i-h3-i2s",
		.data = &sun8i_h3_i2s_quirks,
	},
	{
		.compatible = "allwinner,sun50i-a64-i2s-codec",
		.data = &sun50i_a64_i2s_ap_quirks,
	},
	{ /* sentinel */ },
};
MODULE_DEVICE_TABLE(of, sun4i_i2s_match);

static const struct dev_pm_ops sun4i_i2s_pm_ops = {
	.runtime_resume	 = sun4i_i2s_runtime_resume,
	.runtime_suspend = sun4i_i2s_runtime_suspend,
};

static struct platform_driver sun4i_i2s_driver = {
	.probe  = sun4i_i2s_probe,
	.remove = sun4i_i2s_remove,
	.driver = {
		.name		= "sun4i-i2s",
		.of_match_table	= sun4i_i2s_match,
		.pm		= &sun4i_i2s_pm_ops,
	},
};
module_platform_driver(sun4i_i2s_driver);

MODULE_AUTHOR("Sergey Suloev <ssuloev@orpaltech.com>");
MODULE_DESCRIPTION("Allwinner sunXi I2S interface driver");
MODULE_LICENSE("GPL");
