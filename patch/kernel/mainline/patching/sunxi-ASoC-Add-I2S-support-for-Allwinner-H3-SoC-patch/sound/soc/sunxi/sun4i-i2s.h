// SPDX-License-Identifier: GPL-2.0+
/*
 * Allwinner sunXi I2S controller driver
 *
 * Copyright 2018 Sergey Suloev <ssuloev@orpaltech.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

#ifndef __LINUX_SUN4I_I2S_H
#define __LINUX_SUN4I_I2S_H


#define SUN4I_I2S_REG_CTRL		0x00	/* Control Register */
#define  SUN4I_I2S_CTRL_SDO_EN_MASK		GENMASK(11,8)
#define  SUN4I_I2S_CTRL_SDO_EN(lines)		(((1 << lines) - 1) << 8)
#define  SUN4I_I2S_CTRL_SLAVE_MASK		BIT(5)
#define  SUN4I_I2S_CTRL_SLAVE			(1 << 5)
#define  SUN4I_I2S_CTRL_MASTER			(0 << 5)
#define  SUN4I_I2S_CTRL_MODE_MASK		BIT(4)
#define  SUN4I_I2S_CTRL_MODE_PCM		(1 << 4)
#define  SUN4I_I2S_CTRL_MODE_I2S		(0 << 4)
#define  SUN4I_I2S_CTRL_LOOPBACK		BIT(3)
#define  SUN4I_I2S_CTRL_TX_EN			BIT(2)
#define  SUN4I_I2S_CTRL_RX_EN			BIT(1)
#define  SUN4I_I2S_CTRL_GLOB_EN			BIT(0)

#define  SUN8I_I2S_CTRL_BCLK_OUT		BIT(18)
#define  SUN8I_I2S_CTRL_LRCK_OUT		BIT(17)

#define  SUN8I_I2S_CTRL_MODE_MASK		GENMASK(5,4)
#define  SUN8I_I2S_CTRL_MODE_PCM		(0 << 4)
#define  SUN8I_I2S_CTRL_MODE_LEFT_J		(1 << 4)
#define  SUN8I_I2S_CTRL_MODE_RIGHT_J		(2 << 4)


#define SUN4I_I2S_REG_FMT0		0x04	/* Format 0 Register */
#define  SUN4I_I2S_FMT0_DSP_MODE_MASK		BIT(7)
#define  SUN4I_I2S_FMT0_DSP_MODE_A		(0 << 7)
#define  SUN4I_I2S_FMT0_DSP_MODE_B		(1 << 7)
#define  SUN4I_I2S_FMT0_SR_MASK			GENMASK(5,4)
#define  SUN4I_I2S_FMT0_SR(sr)			((sr) << 4)
#define  SUN4I_I2S_FMT0_WSS_MASK		GENMASK(3,2)
#define  SUN4I_I2S_FMT0_WSS(ws)			((ws) << 2)

#define  SUN4I_I2S_FMT0_FMT_MASK		GENMASK(1,0)
#define  SUN4I_I2S_FMT0_FMT_RIGHT_J		(2 << 0)
#define  SUN4I_I2S_FMT0_FMT_LEFT_J		(1 << 0)
#define  SUN4I_I2S_FMT0_FMT_I2S			(0 << 0)

#define  SUN4I_I2S_POLARITY_INVERT		1
#define  SUN4I_I2S_POLARITY_NORMAL		0

#define  SUN8I_I2S_FMT0_SR_MASK			GENMASK(6,4)
#define  SUN8I_I2S_FMT0_SR(sr)			((sr) << 4)
#define  SUN8I_I2S_FMT0_SW_MASK			GENMASK(2,0)
#define  SUN8I_I2S_FMT0_SW(sw)			((sw) << 0)

#define  SUN8I_I2S_LRCK_PERIOD_MASK		GENMASK(17,8)
#define  SUN8I_I2S_LRCK_PERIOD(prd)		((prd - 1) << 8)
#define  SUN8I_I2S_LRCK_MAX_PERIOD		1024
#define  SUN8I_I2S_LRCKR_PERIOD_MASK		GENMASK(29,20)
#define  SUN8I_I2S_LRCKR_PERIOD(prd)		((prd - 1) << 20)

#define  SUN8I_I2S_PCM_SYNC_WIDTH		BIT(30)
#define  SUN8I_I2S_PCM_SYNC_SHORT		(0 << 30)	/*1 BCLK period*/
#define  SUN8I_I2S_PCM_SYNC_LONG		(1 << 30)	/*2 BCLK period*/

#define SUN4I_I2S_REG_FMT1		0x08	/* Format 1 Register */
#define  SUN4I_I2S_PCM_SYNC_WIDTH		BIT(4)
#define  SUN4I_I2S_PCM_SYNC_SHORT		(1 << 4)	/*1 BCLK period*/
#define  SUN4I_I2S_PCM_SYNC_LONG		(0 << 4)	/*2 BCLK period*/
#define  SUN4I_I2S_FMT1_SEXT_MASK		BIT(8)
#define  SUN4I_I2S_FMT1_SEXT(sext)		((sext) << 8)
#define  SUN4I_I2S_FMT1_PCM_SYNC_PRD_MASK	GENMASK(14,12)
#define  SUN4I_I2S_FMT1_PCM_SYNC_PRD(prd)	((prd) << 12)


#define SUN4I_I2S_REG_RX_FIFO		0x10	/* RX FIFO Register */


#define SUN4I_I2S_REG_FIFO_CTRL		0x14	/* FIFO Control Register */
#define  SUN4I_I2S_FIFO_CTRL_TX_IM_MASK		BIT(2)
#define  SUN4I_I2S_FIFO_CTRL_TX_IM(mod)		((mod) << 2)
#define  SUN4I_I2S_FIFO_CTRL_RX_OM_MASK		GENMASK(1,0)
#define  SUN4I_I2S_FIFO_CTRL_RX_OM(mod)		((mod) << 0)
#define  SUN4I_I2S_FIFO_RX_TL_MASK		GENMASK(9,4)
#define  SUN4I_I2S_FIFO_RX_TL(tl)		((tl) << 4)
#define  SUN4I_I2S_FIFO_TX_TL_MASK		GENMASK(18,12)
#define  SUN4I_I2S_FIFO_TX_TL(tl)		((tl) << 12)
#define  SUN4I_I2S_FIFO_FLUSH_TX		BIT(25)
#define  SUN4I_I2S_FIFO_FLUSH_RX		BIT(24)


#define SUN4I_I2S_REG_FIFO_STA		0x18	/* FIFO Status Register */


#define SUN4I_I2S_REG_TX_FIFO		0x0c	/* TX FIFO Register */
#define SUN8I_I2S_REG_TX_FIFO		0x20	/* TX FIFO Register */


#define SUN4I_I2S_REG_INT_STA		0x20	/* Interrupt Status Register */
#define SUN8I_I2S_REG_INT_STA		0x0c	/* Interrupt Status Register */


#define SUN4I_I2S_REG_DMA_INT_CTRL	0x1c	/* Interrupt/DMA Control Register */
#define  SUN4I_I2S_TX_DRQ_EN			BIT(7)
#define  SUN4I_I2S_RX_DRQ_EN			BIT(3)


#define SUN4I_I2S_REG_CLKDIV		0x24	/* Clock Divide Register */
#define  SUN4I_I2S_CLKDIV_MCLK_EN		BIT(7)
#define  SUN4I_I2S_CLKDIV_MCLK_MASK		GENMASK(3,0)
#define  SUN4I_I2S_CLKDIV_MCLK(div)		((div) << 0)
#define  SUN4I_I2S_CLKDIV_BCLK_MASK		GENMASK(6,4)
#define  SUN4I_I2S_CLKDIV_BCLK(div)		((div) << 4)

#define  SUN8I_I2S_CLKDIV_BCLK_MASK		GENMASK(7,4)
#define  SUN8I_I2S_CLKDIV_MCLK_EN		BIT(8)


#define SUN4I_I2S_REG_TX_COUNT		0x28	/* TX Sample Counter Register */
#define SUN4I_I2S_REG_RX_COUNT		0x2c	/* RX Sample Counter Register */


#define SUN8I_I2S_REG_CHAN_CFG		0x30
#define  SUN8I_I2S_CHAN_CFG_RX_SLOT_NUM_MASK	GENMASK(6,4)
#define  SUN8I_I2S_CHAN_CFG_RX_SLOT_NUM(ch)	(((ch) - 1) << 4)
#define  SUN8I_I2S_CHAN_CFG_TX_SLOT_NUM_MASK	GENMASK(2,0)
#define  SUN8I_I2S_CHAN_CFG_TX_SLOT_NUM(ch)	(((ch) - 1) << 0)


#define SUN4I_I2S_REG_TX_CHAN_SEL	0x30	/* TX Channel Select Register */
#define SUN8I_I2S_REG_TX_CHAN_SEL	0x34
#define SUN4I_I2S_REG_RX_CHAN_SEL	0x38    /* RX Channel Select Register */
#define SUN8I_I2S_REG_RX_CHAN_SEL	0x54
#define  SUN8I_I2S_TX_CHAN_SEL_EN_MASK		GENMASK(11,4)
#define  SUN8I_I2S_TX_CHAN_SEL_EN(ch)		(((1 << (ch)) - 1) << 4)
#define  SUN4I_I2S_CHAN_SEL(num)		((num) - 1)
#define  SUN8I_I2S_CHAN_SEL_OFFSET_MASK		GENMASK(13,12)
#define  SUN8I_I2S_CHAN_SEL_OFFSET(off)		((off) << 12)


#define SUN4I_I2S_REG_TX_CHAN_MAP	0x34	/* TX Channel Mapping Register */
#define SUN8I_I2S_REG_TX_CHAN_MAP	0x44
#define SUN4I_I2S_REG_RX_CHAN_MAP	0x3c	/* RX Channel Mapping Register */
#define SUN8I_I2S_REG_RX_CHAN_MAP	0x58
#define  SUN4I_I2S_CHAN_MAP(chan, samp)		((samp) << ((chan) << 2))


/* regmap fields */
enum {
	FIELD_MCLK_OUT_EN,	/* MCLK Enable */

	FIELD_BCLK_DIV,
	FIELD_MCLK_DIV,

	FIELD_BCLK_POLARITY,	/* BCLK Polarity */
	FIELD_LRCK_POLARITY,	/* LRCK	Polarity */

	FIELD_SIGN_EXT,		/* Sign Extend in slot */

	FIELD_TX_CHAN_MAP,	/* TX Channel Mapping */
	FIELD_RX_CHAN_MAP,	/* RX Channel Mapping */
	FIELD_TX_CHAN_SEL,	/* TX Channel Select */
	FIELD_RX_CHAN_SEL,	/* RX Channel Select */

	/* Keep last */
	REGMAP_NUM_FIELDS,
};

struct sun4i_i2s;

struct sun4i_i2s_clkdiv {
	u8	div;
	u8	val;
};

enum {
	BCLK_PARENT_MCLK,
	BCLK_PARENT_PLL,
};

struct sun4i_i2s_quirks {
	bool				has_reset;
	u32				reg_offset_txdata;
	const struct regmap_config	*regmap_cfg;
	const struct reg_field		*reg_fields;

	const struct sun4i_i2s_clkdiv	*bclk_div;
	unsigned int			num_bclkdiv;

	const struct sun4i_i2s_clkdiv	*mclk_div;
	unsigned int			num_mclkdiv;

	u32				playback_formats;
	u32				capture_formats;

	int				bclk_parent;

	/* SoC-specific DAI configuration */
	int (*set_format)(struct sun4i_i2s *i2s, u32 fmt);
	int (*set_hw_config)(struct snd_soc_dai *dai,
			     struct snd_pcm_hw_params *params);
};

struct sun4i_i2s {
	struct device		*dev;
	struct clk		*bus_clk;
	struct clk		*mod_clk;
	struct regmap		*regmap;
	struct regmap_field	*fields[REGMAP_NUM_FIELDS];
	struct reset_control	*rst;

	bool		loopback;
	bool		bit_clk_master;
	bool		is_pcm;

	unsigned long	mclk_rate;

	u32		tdm_slots;
//	u32		bclk_ratio;
	u32		slot_width;
	u32		frame_length;

	struct snd_dmaengine_dai_dma_data
			dma_data[SNDRV_PCM_STREAM_LAST + 1];

	const struct sun4i_i2s_quirks	*quirks;
};

#endif	// __LINUX_SUN4I_I2S_H
