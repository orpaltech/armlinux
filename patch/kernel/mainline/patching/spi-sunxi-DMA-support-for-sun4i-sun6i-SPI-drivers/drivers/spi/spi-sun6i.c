/*
 * Copyright (C) 2012 - 2014 Allwinner Tech
 * Pan Nan <pannan@allwinnertech.com>
 *
 * Copyright (C) 2014 Maxime Ripard
 * Maxime Ripard <maxime.ripard@free-electrons.com>
 *
 * Copyright (C) 2018 ORPALTECH Inc
 * Sergey Suloev <ssuloev@orpaltech.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 */

#include <linux/clk.h>
#include <linux/delay.h>
#include <linux/device.h>
#include <linux/dmaengine.h>
#include <linux/dma-mapping.h>
#include <linux/interrupt.h>
#include <linux/io.h>
#include <linux/module.h>
#include <linux/of_device.h>
#include <linux/platform_device.h>
#include <linux/pm_runtime.h>
#include <linux/reset.h>

#include <linux/spi/spi.h>


#define SUN6I_FIFO_DEPTH		128
#define SUN8I_FIFO_DEPTH		64


#define SUN6I_GBL_CTL_REG		0x04
#define SUN6I_GBL_CTL_BUS_ENABLE		BIT(0)
#define SUN6I_GBL_CTL_MASTER			BIT(1)
#define SUN6I_GBL_CTL_TP			BIT(7)
#define SUN6I_GBL_CTL_RST			BIT(31)


#define SUN6I_TFR_CTL_REG		0x08
#define SUN6I_TFR_CTL_CPHA			BIT(0)
#define SUN6I_TFR_CTL_CPOL			BIT(1)
#define SUN6I_TFR_CTL_SPOL			BIT(2)
#define SUN6I_TFR_CTL_CS_MASK			0x30
#define SUN6I_TFR_CTL_CS(cs)			(((cs) << 4) & SUN6I_TFR_CTL_CS_MASK)
#define SUN6I_TFR_CTL_CS_MANUAL			BIT(6)
#define SUN6I_TFR_CTL_CS_LEVEL			BIT(7)
#define SUN6I_TFR_CTL_DHB			BIT(8)
#define SUN6I_TFR_CTL_FBS			BIT(12)
#define SUN6I_TFR_CTL_XCH			BIT(31)


#define SUN6I_INT_CTL_REG		0x10
#define SUN6I_INT_CTL_RF_RDY			BIT(0)
#define SUN6I_INT_CTL_TF_ERQ			BIT(4)
#define SUN6I_INT_CTL_RF_OVF			BIT(8)
#define SUN6I_INT_CTL_TC			BIT(12)


#define SUN6I_INT_STA_REG		0x14


#define SUN6I_FIFO_CTL_REG		0x18
#define SUN6I_FIFO_CTL_RF_RDY_TRIG_LEVEL_MASK	0xff
#define SUN6I_FIFO_CTL_RF_RDY_TRIG_LEVEL_POS	0
#define SUN6I_FIFO_CTL_RF_DRQ_EN		BIT(8)
#define SUN6I_FIFO_CTL_RF_RST			BIT(15)
#define SUN6I_FIFO_CTL_TF_ERQ_TRIG_LEVEL_MASK	0xff
#define SUN6I_FIFO_CTL_TF_ERQ_TRIG_LEVEL_POS	16
#define SUN6I_FIFO_CTL_TF_DRQ_EN		BIT(24)
#define SUN6I_FIFO_CTL_TF_RST			BIT(31)
#define SUN6I_FIFO_CTL_DMA_DEDICATE		BIT(9)|BIT(25)


#define SUN6I_FIFO_STA_REG		0x1c
#define SUN6I_FIFO_STA_RF_CNT_MASK		0x7f
#define SUN6I_FIFO_STA_RF_CNT_BITS		0
#define SUN6I_FIFO_STA_TF_CNT_MASK		0x7f
#define SUN6I_FIFO_STA_TF_CNT_BITS		16

#define SUN6I_CLK_CTL_REG		0x24
#define SUN6I_CLK_CTL_CDR2_MASK			0xff
#define SUN6I_CLK_CTL_CDR2(div)			(((div) & SUN6I_CLK_CTL_CDR2_MASK) << 0)
#define SUN6I_CLK_CTL_CDR1_MASK			0xf
#define SUN6I_CLK_CTL_CDR1(div)			(((div) & SUN6I_CLK_CTL_CDR1_MASK) << 8)
#define SUN6I_CLK_CTL_DRS			BIT(12)

#define SUN6I_MAX_XFER_SIZE		0xffffff

#define SUN6I_BURST_CNT_REG		0x30
#define SUN6I_BURST_CNT(cnt)			((cnt) & SUN6I_MAX_XFER_SIZE)

#define SUN6I_XMIT_CNT_REG		0x34
#define SUN6I_XMIT_CNT(cnt)			((cnt) & SUN6I_MAX_XFER_SIZE)

#define SUN6I_BURST_CTL_CNT_REG		0x38
#define SUN6I_BURST_CTL_CNT_STC(cnt)		((cnt) & SUN6I_MAX_XFER_SIZE)

#define SUN6I_TXDATA_REG		0x200
#define SUN6I_RXDATA_REG		0x300

#define SUN6I_SPI_MODE_BITS		(SPI_CPOL | SPI_CPHA | SPI_CS_HIGH | SPI_LSB_FIRST)

#define SUN6I_SPI_MAX_SPEED_HZ		100000000
#define SUN6I_SPI_MIN_SPEED_HZ		3000

struct sun6i_spi {
	void __iomem		*base_addr;
	struct clk		*hclk;
	struct clk		*mclk;
	struct reset_control	*rstc;

	const u8		*tx_buf;
	u8			*rx_buf;
	int			len;
	unsigned long		fifo_depth;
};

static inline u32 sun6i_spi_read(struct sun6i_spi *sspi, u32 reg)
{
	return readl(sspi->base_addr + reg);
}

static inline void sun6i_spi_write(struct sun6i_spi *sspi, u32 reg, u32 value)
{
	writel(value, sspi->base_addr + reg);
}

static inline void sun6i_spi_set(struct sun6i_spi *sspi, u32 addr, u32 val)
{
	u32 reg = sun6i_spi_read(sspi, addr);

	reg |= val;
	sun6i_spi_write(sspi, addr, reg);
}

static inline void sun6i_spi_unset(struct sun6i_spi *sspi, u32 addr, u32 val)
{
	u32 reg = sun6i_spi_read(sspi, addr);

	reg &= ~val;
	sun6i_spi_write(sspi, addr, reg);
}

static inline u32 sun6i_spi_get_tx_fifo_count(struct sun6i_spi *sspi)
{
	u32 reg = sun6i_spi_read(sspi, SUN6I_FIFO_STA_REG);

	reg >>= SUN6I_FIFO_STA_TF_CNT_BITS;

	return reg & SUN6I_FIFO_STA_TF_CNT_MASK;
}

static inline void sun6i_spi_drain_fifo(struct sun6i_spi *sspi, int len)
{
	u32 reg, cnt;
	u8 byte;

	/* See how much data is available */
	reg = sun6i_spi_read(sspi, SUN6I_FIFO_STA_REG);
	reg &= SUN6I_FIFO_STA_RF_CNT_MASK;
	cnt = reg >> SUN6I_FIFO_STA_RF_CNT_BITS;

	if (len > cnt)
		len = cnt;

	while (len--) {
		byte = readb(sspi->base_addr + SUN6I_RXDATA_REG);
		if (sspi->rx_buf)
			*sspi->rx_buf++ = byte;
	}
}

static inline void sun6i_spi_fill_fifo(struct sun6i_spi *sspi, int len)
{
	u32 cnt;
	u8 byte;

	/* See how much data we can fit */
	cnt = sspi->fifo_depth - sun6i_spi_get_tx_fifo_count(sspi);

	len = min3(len, (int)cnt, sspi->len);

	while (len--) {
		byte = sspi->tx_buf ? *sspi->tx_buf++ : 0;
		writeb(byte, sspi->base_addr + SUN6I_TXDATA_REG);
		sspi->len--;
	}
}

static bool sun6i_spi_can_dma(struct spi_master *master,
			      struct spi_device *spi,
			      struct spi_transfer *tfr)
{
	struct sun6i_spi *sspi = spi_master_get_devdata(master);

	return tfr->len > sspi->fifo_depth;
}

static void sun6i_spi_set_cs(struct spi_device *spi, bool enable)
{
	struct sun6i_spi *sspi = spi_master_get_devdata(spi->master);
	u32 reg;

	reg = sun6i_spi_read(sspi, SUN6I_TFR_CTL_REG);
	reg &= ~SUN6I_TFR_CTL_CS_MASK;
	reg |= SUN6I_TFR_CTL_CS(spi->chip_select);

	if (enable)
		reg |= SUN6I_TFR_CTL_CS_LEVEL;
	else
		reg &= ~SUN6I_TFR_CTL_CS_LEVEL;

	/* set flag for "reverse" polarity in the register */
	if (spi->mode & SPI_CS_HIGH)
		reg &= ~SUN6I_TFR_CTL_SPOL;
	else
		reg |= SUN6I_TFR_CTL_SPOL;

	/* We want to control the chip select manually */
	reg |= SUN6I_TFR_CTL_CS_MANUAL;

	sun6i_spi_write(sspi, SUN6I_TFR_CTL_REG, reg);
}

static size_t sun6i_spi_max_transfer_size(struct spi_device *spi)
{
	struct spi_master *master = spi->master;
	struct sun6i_spi *sspi = spi_master_get_devdata(master);

	if (master->can_dma)
		return SUN6I_MAX_XFER_SIZE;

	return sspi->fifo_depth;
}

static int sun6i_spi_prepare_message(struct spi_master *master,
				     struct spi_message *msg)
{
	struct spi_device *spi = msg->spi;
	struct sun6i_spi *sspi = spi_master_get_devdata(master);
	u32 reg;

	/*
	 * Setup the transfer control register: Chip Select,
	 * polarities, etc.
	 */
	reg = sun6i_spi_read(sspi, SUN6I_TFR_CTL_REG);

	if (spi->mode & SPI_CPOL)
		reg |= SUN6I_TFR_CTL_CPOL;
	else
		reg &= ~SUN6I_TFR_CTL_CPOL;

	if (spi->mode & SPI_CPHA)
		reg |= SUN6I_TFR_CTL_CPHA;
	else
		reg &= ~SUN6I_TFR_CTL_CPHA;

	if (spi->mode & SPI_LSB_FIRST)
		reg |= SUN6I_TFR_CTL_FBS;
	else
		reg &= ~SUN6I_TFR_CTL_FBS;

	sun6i_spi_write(sspi, SUN6I_TFR_CTL_REG, reg);

	return 0;
}

static int sun6i_spi_wait_for_transfer(struct spi_device *spi,
				       struct spi_transfer *tfr)
{
	struct spi_master *master = spi->master;
	unsigned int start, end, tx_time;
	unsigned int timeout;

	/* smart wait for completion */
	tx_time = max(tfr->len * 8 * 2 / (tfr->speed_hz / 1000), 100U);
	start = jiffies;
	timeout = wait_for_completion_timeout(&master->xfer_completion,
					      msecs_to_jiffies(tx_time));
	end = jiffies;
	if (!timeout) {
		dev_warn(&master->dev,
			 "%s: timeout transferring %u bytes@%iHz for %i(%i)ms",
			 dev_name(&spi->dev), tfr->len, tfr->speed_hz,
			 jiffies_to_msecs(end - start), tx_time);
		return -ETIMEDOUT;
	}

	return 0;
}

static inline int sun6i_spi_do_transfer(struct spi_device *spi,
					struct spi_transfer *tfr)
{
	struct spi_master *master = spi->master;
	struct sun6i_spi *sspi = spi_master_get_devdata(master);

        /* Start transfer */
        sun6i_spi_set(sspi, SUN6I_TFR_CTL_REG, SUN6I_TFR_CTL_XCH);

        /* Wait for completion */
        return sun6i_spi_wait_for_transfer(spi, tfr);
}

static int sun6i_spi_transfer_one_pio(struct spi_device *spi,
				      struct spi_transfer *tfr)
{
	struct spi_master *master = spi->master;
	struct sun6i_spi *sspi = spi_master_get_devdata(master);
	int ret;

	/* Disable DMA requests */
	sun6i_spi_write(sspi, SUN6I_FIFO_CTL_REG, 0);

	sun6i_spi_fill_fifo(sspi, sspi->fifo_depth);

	/* Enable transfer complete IRQ */
	sun6i_spi_set(sspi, SUN6I_INT_CTL_REG, SUN6I_INT_CTL_TC);

	ret = sun6i_spi_do_transfer(spi, tfr);

	sun6i_spi_write(sspi, SUN6I_INT_CTL_REG, 0);

	return ret;
}

static void sun6i_spi_dma_callback(void *param)
{
	struct spi_master *master = param;

	dev_dbg(&master->dev, "DMA transfer complete\n");
	spi_finalize_current_transfer(master);
}

static int sun6i_spi_dmap_prep_tx(struct spi_master *master,
				  struct spi_transfer *tfr,
				  dma_cookie_t *cookie)
{
	struct dma_async_tx_descriptor *chan_desc = NULL;

	chan_desc = dmaengine_prep_slave_sg(master->dma_tx,
					    tfr->tx_sg.sgl, tfr->tx_sg.nents,
					    DMA_TO_DEVICE,
					    DMA_PREP_INTERRUPT | DMA_CTRL_ACK);
	if (!chan_desc) {
		dev_err(&master->dev,
			"Couldn't prepare TX DMA slave\n");
		return -EIO;
	}

	chan_desc->callback = sun6i_spi_dma_callback;
	chan_desc->callback_param = master;

	*cookie = dmaengine_submit(chan_desc);
	dma_async_issue_pending(master->dma_tx);

	return 0;
}

static int sun6i_spi_dmap_prep_rx(struct spi_master *master,
				  struct spi_transfer *tfr,
				  dma_cookie_t *cookie)
{
	struct dma_async_tx_descriptor *chan_desc = NULL;

	chan_desc = dmaengine_prep_slave_sg(master->dma_rx,
					    tfr->rx_sg.sgl, tfr->rx_sg.nents,
					    DMA_FROM_DEVICE,
					    DMA_PREP_INTERRUPT | DMA_CTRL_ACK);
	if (!chan_desc) {
		dev_err(&master->dev,
			"Couldn't prepare RX DMA slave\n");
		return -EIO;
	}

	chan_desc->callback = sun6i_spi_dma_callback;
	chan_desc->callback_param = master;

	*cookie = dmaengine_submit(chan_desc);
	dma_async_issue_pending(master->dma_rx);

	return 0;
}

static int sun6i_spi_transfer_one_dma(struct spi_device *spi,
				      struct spi_transfer *tfr)
{
	struct spi_master *master = spi->master;
	struct sun6i_spi *sspi = spi_master_get_devdata(master);
	dma_cookie_t tx_cookie = 0,rx_cookie = 0;
	enum dma_status status;
	int ret;
	u32 reg, trig_level = 0;

	dev_dbg(&master->dev, "Using DMA mode for transfer\n");

	reg = sun6i_spi_read(sspi, SUN6I_FIFO_CTL_REG);

	if (sspi->tx_buf) {
		ret = sun6i_spi_dmap_prep_tx(master, tfr, &tx_cookie);
		if (ret)
			goto out;

		reg |= SUN6I_FIFO_CTL_TF_DRQ_EN;

		trig_level = sspi->fifo_depth;
		reg &= ~SUN6I_FIFO_CTL_TF_ERQ_TRIG_LEVEL_MASK;
		reg |= (trig_level << SUN6I_FIFO_CTL_TF_ERQ_TRIG_LEVEL_POS);
	}

	if (sspi->rx_buf) {
		ret = sun6i_spi_dmap_prep_rx(master, tfr, &rx_cookie);
		if (ret)
			goto out;

		reg |= SUN6I_FIFO_CTL_RF_DRQ_EN;

		trig_level = 1;
		reg &= ~SUN6I_FIFO_CTL_RF_RDY_TRIG_LEVEL_MASK;
		reg |= (trig_level << SUN6I_FIFO_CTL_RF_RDY_TRIG_LEVEL_POS);
	}

	/* Enable Dedicated DMA requests */
	sun6i_spi_write(sspi, SUN6I_FIFO_CTL_REG,
			reg | SUN6I_FIFO_CTL_DMA_DEDICATE);

	ret = sun6i_spi_do_transfer(spi, tfr);
	if (ret)
		goto out;

	if (sspi->tx_buf && (status = dma_async_is_tx_complete(master->dma_tx,
			tx_cookie, NULL, NULL))) {
		dev_warn(&master->dev,
			"DMA returned completion status of: %s\n",
			status == DMA_ERROR ? "error" : "in progress");
	}
	if (sspi->rx_buf && (status = dma_async_is_tx_complete(master->dma_rx,
			rx_cookie, NULL, NULL))) {
		dev_warn(&master->dev,
			"DMA returned completion status of: %s\n",
			status == DMA_ERROR ? "error" : "in progress");
	}

out:
	if (ret) {
		dev_dbg(&master->dev, "DMA channel teardown\n");
		if (sspi->tx_buf)
			dmaengine_terminate_sync(master->dma_tx);
		if (sspi->rx_buf)
			dmaengine_terminate_sync(master->dma_rx);
	}

	sun6i_spi_drain_fifo(sspi, sspi->fifo_depth);

	sun6i_spi_write(sspi, SUN6I_INT_CTL_REG, 0);

	return ret;
}

static int sun6i_spi_transfer_one(struct spi_master *master,
				  struct spi_device *spi,
				  struct spi_transfer *tfr)
{
	struct sun6i_spi *sspi = spi_master_get_devdata(master);
	unsigned int mclk_rate, div;
	unsigned int tx_len = 0;
	u32 reg;

	/* A zero length transfer never finishes if programmed
	   in the hardware */
	if (!tfr->len)
		return 0;

	if (tfr->len > SUN6I_MAX_XFER_SIZE)
		return -EMSGSIZE;

	if (!master->can_dma) {
		/* Don't support transfer larger than the FIFO */
		if (tfr->len > sspi->fifo_depth)
			return -EMSGSIZE;
	}

	sspi->tx_buf = tfr->tx_buf;
	sspi->rx_buf = tfr->rx_buf;
	sspi->len = tfr->len;

	/* Clear pending interrupts */
	sun6i_spi_write(sspi, SUN6I_INT_STA_REG, ~0);

	/* Reset FIFO */
	sun6i_spi_write(sspi, SUN6I_FIFO_CTL_REG,
			SUN6I_FIFO_CTL_RF_RST | SUN6I_FIFO_CTL_TF_RST);

	reg = sun6i_spi_read(sspi, SUN6I_TFR_CTL_REG);
	/*
	 * If it's a TX only transfer, we don't want to fill the RX
	 * FIFO with bogus data
	 */
	if (sspi->rx_buf)
		reg &= ~SUN6I_TFR_CTL_DHB;
	else
		reg |= SUN6I_TFR_CTL_DHB;

	sun6i_spi_write(sspi, SUN6I_TFR_CTL_REG, reg);

	/* Ensure that we have a parent clock fast enough */
	mclk_rate = clk_get_rate(sspi->mclk);
	if (mclk_rate < (2 * tfr->speed_hz)) {
		clk_set_rate(sspi->mclk, 2 * tfr->speed_hz);
		mclk_rate = clk_get_rate(sspi->mclk);
	}

	/*
	 * Setup clock divider.
	 *
	 * We have two choices there. Either we can use the clock
	 * divide rate 1, which is calculated thanks to this formula:
	 * SPI_CLK = MOD_CLK / (2 ^ cdr)
	 * Or we can use CDR2, which is calculated with the formula:
	 * SPI_CLK = MOD_CLK / (2 * (cdr + 1))
	 * Wether we use the former or the latter is set through the
	 * DRS bit.
	 *
	 * First try CDR2, and if we can't reach the expected
	 * frequency, fall back to CDR1.
	 */
	div = mclk_rate / (2 * tfr->speed_hz);
	if (div <= (SUN6I_CLK_CTL_CDR2_MASK + 1)) {
		if (div > 0)
			div--;

		reg = SUN6I_CLK_CTL_CDR2(div) | SUN6I_CLK_CTL_DRS;
	} else {
		div = ilog2(mclk_rate) - ilog2(tfr->speed_hz);
		reg = SUN6I_CLK_CTL_CDR1(div);
	}

	sun6i_spi_write(sspi, SUN6I_CLK_CTL_REG, reg);

	/* Setup the transfer now... */
	if (sspi->tx_buf)
		tx_len = tfr->len;

	/* Setup the counters */
	sun6i_spi_write(sspi, SUN6I_BURST_CNT_REG, SUN6I_BURST_CNT(tfr->len));
	sun6i_spi_write(sspi, SUN6I_XMIT_CNT_REG, SUN6I_XMIT_CNT(tx_len));
	sun6i_spi_write(sspi, SUN6I_BURST_CTL_CNT_REG,
			SUN6I_BURST_CTL_CNT_STC(tx_len));

	if (sun6i_spi_can_dma(master, spi, tfr))
		return sun6i_spi_transfer_one_dma(spi, tfr);

	return sun6i_spi_transfer_one_pio(spi, tfr);
}

static irqreturn_t sun6i_spi_handler(int irq, void *dev_id)
{
	struct spi_master *master = dev_id;
        struct sun6i_spi *sspi = spi_master_get_devdata(master);
	u32 reg;

	reg = sun6i_spi_read(sspi, SUN6I_INT_STA_REG);

	/* Transfer complete */
	if (reg & SUN6I_INT_CTL_TC) {
		sun6i_spi_write(sspi, SUN6I_INT_STA_REG,
				SUN6I_INT_CTL_TC);
		sun6i_spi_drain_fifo(sspi, sspi->fifo_depth);
		spi_finalize_current_transfer(master);
		return IRQ_HANDLED;
	}

	return IRQ_NONE;
}

static int sun6i_spi_dma_setup(struct platform_device *pdev,
			       struct resource *res)
{
	struct spi_master *master = platform_get_drvdata(pdev);
	struct dma_slave_config dma_sconf;
	int ret;

	master->dma_tx = dma_request_slave_channel_reason(&pdev->dev, "tx");
	if (IS_ERR(master->dma_tx)) {
		dev_err(&pdev->dev, "Unable to acquire DMA TX channel\n");
		ret = PTR_ERR(master->dma_tx);
		goto out;
	}

	dma_sconf.direction = DMA_MEM_TO_DEV;
	dma_sconf.src_addr_width = DMA_SLAVE_BUSWIDTH_1_BYTE;
	dma_sconf.dst_addr_width = DMA_SLAVE_BUSWIDTH_1_BYTE;
	dma_sconf.dst_addr = res->start + SUN6I_TXDATA_REG;
	dma_sconf.src_maxburst = 1;
	dma_sconf.dst_maxburst = 1;

	ret = dmaengine_slave_config(master->dma_tx, &dma_sconf);
	if (ret) {
		dev_err(&pdev->dev, "Unable to configure DMA TX slave\n");
		goto err_rel_tx;
	}

	master->dma_rx = dma_request_slave_channel_reason(&pdev->dev, "rx");
	if (IS_ERR(master->dma_rx)) {
		dev_err(&pdev->dev, "Unable to acquire DMA RX channel\n");
		ret = PTR_ERR(master->dma_rx);
		goto err_rel_tx;
	}

	dma_sconf.direction = DMA_DEV_TO_MEM;
	dma_sconf.src_addr_width = DMA_SLAVE_BUSWIDTH_1_BYTE;
	dma_sconf.dst_addr_width = DMA_SLAVE_BUSWIDTH_1_BYTE;
	dma_sconf.src_addr = res->start + SUN6I_RXDATA_REG;
	dma_sconf.src_maxburst = 1;
	dma_sconf.dst_maxburst = 1;

	ret = dmaengine_slave_config(master->dma_rx, &dma_sconf);
	if (ret) {
		dev_err(&pdev->dev, "Unable to configure DMA RX slave\n");
		goto err_rel_rx;
	}

	/* don't set can_dma unless both channels are valid*/
	master->can_dma = sun6i_spi_can_dma;

	return 0;

err_rel_rx:
	dma_release_channel(master->dma_rx);
err_rel_tx:
	dma_release_channel(master->dma_tx);
out:
	master->dma_tx = NULL;
	master->dma_rx = NULL;
	return ret;
}

static void sun6i_spi_dma_release(struct spi_master *master)
{
	if (master->can_dma) {
		dma_release_channel(master->dma_rx);
		dma_release_channel(master->dma_tx);
	}
}

static int sun6i_spi_runtime_resume(struct device *dev)
{
	struct spi_master *master = dev_get_drvdata(dev);
	struct sun6i_spi *sspi = spi_master_get_devdata(master);
	int ret;

	ret = clk_prepare_enable(sspi->hclk);
	if (ret) {
		dev_err(dev, "Couldn't enable AHB clock\n");
		goto out;
	}

	ret = clk_prepare_enable(sspi->mclk);
	if (ret) {
		dev_err(dev, "Couldn't enable module clock\n");
		goto err_dis_hclk;
	}

	ret = reset_control_deassert(sspi->rstc);
	if (ret) {
		dev_err(dev, "Couldn't deassert the device from reset\n");
		goto err_dis_mclk;
	}

	sun6i_spi_write(sspi, SUN6I_GBL_CTL_REG,
			SUN6I_GBL_CTL_BUS_ENABLE | SUN6I_GBL_CTL_MASTER | SUN6I_GBL_CTL_TP);

	return 0;

err_dis_mclk:
	clk_disable_unprepare(sspi->mclk);
err_dis_hclk:
	clk_disable_unprepare(sspi->hclk);
out:
	return ret;
}

static int sun6i_spi_runtime_suspend(struct device *dev)
{
	struct spi_master *master = dev_get_drvdata(dev);
	struct sun6i_spi *sspi = spi_master_get_devdata(master);

	reset_control_assert(sspi->rstc);
	clk_disable_unprepare(sspi->mclk);
	clk_disable_unprepare(sspi->hclk);

	return 0;
}

static int sun6i_spi_probe(struct platform_device *pdev)
{
	struct spi_master *master;
	struct sun6i_spi *sspi;
	struct resource	*res;
	int ret = 0, irq;

	master = spi_alloc_master(&pdev->dev, sizeof(*sspi));
	if (!master) {
		dev_err(&pdev->dev, "Unable to allocate SPI Master\n");
		return -ENOMEM;
	}

	master->max_speed_hz = SUN6I_SPI_MAX_SPEED_HZ;
	master->min_speed_hz = SUN6I_SPI_MIN_SPEED_HZ;
	master->num_chipselect = 4;
	master->mode_bits = SUN6I_SPI_MODE_BITS;
	master->bits_per_word_mask = SPI_BPW_MASK(8);
	master->set_cs = sun6i_spi_set_cs;
	master->prepare_message = sun6i_spi_prepare_message;
	master->transfer_one = sun6i_spi_transfer_one;
	master->max_transfer_size = sun6i_spi_max_transfer_size;
	master->dev.of_node = pdev->dev.of_node;
	master->auto_runtime_pm = true;

	platform_set_drvdata(pdev, master);
	sspi = spi_master_get_devdata(master);

	res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	sspi->base_addr = devm_ioremap_resource(&pdev->dev, res);
	if (IS_ERR(sspi->base_addr)) {
		ret = PTR_ERR(sspi->base_addr);
		goto err_free_master;
	}

	irq = platform_get_irq(pdev, 0);
	if (irq < 0) {
		dev_err(&pdev->dev, "No spi IRQ specified\n");
		ret = -ENXIO;
		goto err_free_master;
	}

	ret = devm_request_irq(&pdev->dev, irq, sun6i_spi_handler,
			       0, dev_name(&pdev->dev), master);
	if (ret) {
		dev_err(&pdev->dev, "Cannot request IRQ\n");
		goto err_free_master;
	}

	sspi->fifo_depth = (unsigned long)of_device_get_match_data(&pdev->dev);

	sspi->hclk = devm_clk_get(&pdev->dev, "ahb");
	if (IS_ERR(sspi->hclk)) {
		dev_err(&pdev->dev, "Unable to acquire AHB clock\n");
		ret = PTR_ERR(sspi->hclk);
		goto err_free_master;
	}

	sspi->mclk = devm_clk_get(&pdev->dev, "mod");
	if (IS_ERR(sspi->mclk)) {
		dev_err(&pdev->dev, "Unable to acquire module clock\n");
		ret = PTR_ERR(sspi->mclk);
		goto err_free_master;
	}

	sspi->rstc = devm_reset_control_get_exclusive(&pdev->dev, NULL);
	if (IS_ERR(sspi->rstc)) {
		dev_err(&pdev->dev, "Couldn't get reset controller\n");
		ret = PTR_ERR(sspi->rstc);
		goto err_free_master;
	}

	ret = sun6i_spi_dma_setup(pdev, res);
	if (ret) {
		if (ret == -EPROBE_DEFER) {
			/* wait for the dma driver to load */
			goto err_free_master;
		}
		dev_warn(&pdev->dev, "DMA transfer not supported\n");
	}

	/*
	 * This wake-up/shutdown pattern is to be able to have the
	 * device woken up, even if runtime_pm is disabled
	 */
	ret = sun6i_spi_runtime_resume(&pdev->dev);
	if (ret) {
		dev_err(&pdev->dev, "Couldn't resume the device\n");
		goto err_free_master;
	}

	pm_runtime_set_active(&pdev->dev);
	pm_runtime_enable(&pdev->dev);
	pm_runtime_idle(&pdev->dev);

	ret = devm_spi_register_master(&pdev->dev, master);
	if (ret) {
		dev_err(&pdev->dev, "Couldn't register SPI master\n");
		goto err_pm_disable;
	}

	return 0;

err_pm_disable:
	pm_runtime_disable(&pdev->dev);
	sun6i_spi_runtime_suspend(&pdev->dev);
err_free_master:
	sun6i_spi_dma_release(master);
	spi_master_put(master);
	return ret;
}

static int sun6i_spi_remove(struct platform_device *pdev)
{
	struct spi_master *master = platform_get_drvdata(pdev);

	pm_runtime_force_suspend(&pdev->dev);

	sun6i_spi_dma_release(master);

	return 0;
}

static const struct of_device_id sun6i_spi_match[] = {
	{ .compatible = "allwinner,sun6i-a31-spi", .data = (void *)SUN6I_FIFO_DEPTH },
	{ .compatible = "allwinner,sun8i-h3-spi",  .data = (void *)SUN8I_FIFO_DEPTH },
	{}
};
MODULE_DEVICE_TABLE(of, sun6i_spi_match);

static const struct dev_pm_ops sun6i_spi_pm_ops = {
	.runtime_resume		= sun6i_spi_runtime_resume,
	.runtime_suspend	= sun6i_spi_runtime_suspend,
};

static struct platform_driver sun6i_spi_driver = {
	.probe	= sun6i_spi_probe,
	.remove	= sun6i_spi_remove,
	.driver	= {
		.name		= "sun6i-spi",
		.of_match_table	= sun6i_spi_match,
		.pm		= &sun6i_spi_pm_ops,
	},
};
module_platform_driver(sun6i_spi_driver);

MODULE_AUTHOR("Pan Nan <pannan@allwinnertech.com>");
MODULE_AUTHOR("Maxime Ripard <maxime.ripard@free-electrons.com>");
MODULE_AUTHOR("Sergey Suloev <ssuloev@orpaltech.com>");
MODULE_DESCRIPTION("Allwinner A31 SPI controller driver");
MODULE_LICENSE("GPL");
