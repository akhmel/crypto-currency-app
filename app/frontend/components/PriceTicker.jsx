import React, { useState, useEffect } from 'react'
import {
  Card,
  Group,
  Text,
  Badge,
  ActionIcon,
  Stack,
  ScrollArea,
  LoadingOverlay,
  Tooltip,
  Button
} from '@mantine/core'
import { IconRefresh, IconTrendingUp, IconTrendingDown, IconMinus } from '@tabler/icons-react'

const PriceTicker = ({ cryptoData = [], onRefresh, loading = false }) => {
  const [lastUpdate, setLastUpdate] = useState(new Date())
  const [priceChanges, setPriceChanges] = useState({})

  useEffect(() => {
    if (cryptoData.length > 0) {
      setLastUpdate(new Date())
      
      // Track price changes for animation effects
      cryptoData.forEach(crypto => {
        if (priceChanges[crypto.symbol]) {
          const oldPrice = priceChanges[crypto.symbol]
          const newPrice = crypto.price
          const change = newPrice - oldPrice
          
          // Store the change for visual feedback
          setPriceChanges(prev => ({
            ...prev,
            [crypto.symbol]: {
              price: newPrice,
              change,
              timestamp: Date.now()
            }
          }))
        } else {
          setPriceChanges(prev => ({
            ...prev,
            [crypto.symbol]: {
              price: crypto.price,
              change: 0,
              timestamp: Date.now()
            }
          }))
        }
      })
    }
  }, [cryptoData])

  const getPriceChangeIcon = (change) => {
    if (change > 0) return <IconTrendingUp size={16} />
    if (change < 0) return <IconTrendingDown size={16} />
    return <IconMinus size={16} />
  }

  const getPriceChangeColor = (change) => {
    if (change > 0) return 'green'
    if (change < 0) return 'red'
    return 'gray'
  }

  const formatPrice = (price) => {
    if (price >= 1000) {
      return `$${price.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
    } else if (price >= 1) {
      return `$${price.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 4 })}`
    } else {
      return `$${price.toLocaleString('en-US', { minimumFractionDigits: 4, maximumFractionDigits: 8 })}`
    }
  }

  const formatPercentageChange = (change) => {
    const sign = change >= 0 ? '+' : ''
    return `${sign}${change.toFixed(2)}%`
  }

  const formatLastUpdate = (date) => {
    return date.toLocaleTimeString('en-US', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    })
  }

  const handleRefresh = () => {
    if (onRefresh) {
      onRefresh()
    }
  }

  return (
    <Card shadow="sm" padding="lg" radius="md" withBorder>
      <Group justify="space-between" mb="md">
        <div>
          <Text fw={600} size="lg">
            Live Price Ticker
          </Text>
          <Text size="sm" c="dimmed">
            Real-time cryptocurrency prices
          </Text>
        </div>
        <Group>
          <Text size="xs" c="dimmed">
            Last update: {formatLastUpdate(lastUpdate)}
          </Text>
          <Tooltip label="Refresh Prices">
            <ActionIcon
              variant="subtle"
              onClick={handleRefresh}
              loading={loading}
              size="lg"
            >
              <IconRefresh size={20} />
            </ActionIcon>
          </Tooltip>
        </Group>
      </Group>

      <LoadingOverlay visible={loading} />
      
      <ScrollArea h={400}>
        {cryptoData.length === 0 ? (
          <Stack align="center" py="xl" c="dimmed">
            <Text>No price data available</Text>
            <Text size="sm">Click refresh to load current prices</Text>
          </Stack>
        ) : (
          <Stack gap="sm">
            {cryptoData.map((crypto) => {
              const priceInfo = priceChanges[crypto.symbol]
              const isNewData = priceInfo && (Date.now() - priceInfo.timestamp) < 5000
              
              return (
                <Card
                  key={crypto.symbol}
                  shadow="xs"
                  padding="sm"
                  radius="sm"
                  withBorder
                  style={{
                    borderColor: isNewData && priceInfo.change !== 0 
                      ? getPriceChangeColor(priceInfo.change) 
                      : undefined,
                    transition: 'all 0.3s ease'
                  }}
                >
                  <Group justify="space-between">
                    <div>
                      <Group gap="xs">
                        <Text fw={500} size="lg">
                          {crypto.symbol.replace('USDT', '')}
                        </Text>
                        <Badge variant="light" color="gray" size="sm">
                          {crypto.symbol}
                        </Badge>
                      </Group>
                      
                      <Text size="sm" c="dimmed">
                        {crypto.name || crypto.symbol}
                      </Text>
                    </div>
                    
                    <div style={{ textAlign: 'right' }}>
                      <Text 
                        size="xl" 
                        fw={700}
                        style={{
                          color: isNewData && priceInfo.change !== 0 
                            ? getPriceChangeColor(priceInfo.change) 
                            : undefined
                        }}
                      >
                        {formatPrice(crypto.price)}
                      </Text>
                      
                      <Group gap="xs" justify="flex-end">
                        <ActionIcon
                          variant="subtle"
                          color={getPriceChangeColor(crypto.priceChangePercent)}
                          size="sm"
                        >
                          {getPriceChangeIcon(crypto.priceChangePercent)}
                        </ActionIcon>
                        
                        <Badge
                          variant="light"
                          color={getPriceChangeColor(crypto.priceChangePercent)}
                          size="sm"
                        >
                          {formatPercentageChange(crypto.priceChangePercent)}
                        </Badge>
                      </Group>
                    </div>
                  </Group>
                  
                  <Group justify="space-between" mt="xs" c="dimmed" size="xs">
                    <Text size="xs">
                      Vol: {crypto.volume?.toLocaleString() || 'N/A'}
                    </Text>
                    <Text size="xs">
                      24h: {formatPrice(crypto.highPrice)} / {formatPrice(crypto.lowPrice)}
                    </Text>
                  </Group>
                </Card>
              )
            })}
          </Stack>
        )}
      </ScrollArea>
    </Card>
  )
}

export default PriceTicker
