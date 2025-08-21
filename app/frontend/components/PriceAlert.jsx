import React, { useState } from 'react'
import {
  Card,
  Group,
  Text,
  Badge,
  ActionIcon,
  NumberInput,
  Button,
  Modal,
  Stack,
  Select,
  Switch,
  Tooltip
} from '@mantine/core'
import { IconBell, IconBellOff, IconTrendingUp, IconTrendingDown, IconSettings } from '@tabler/icons-react'

const PriceAlert = ({ crypto, onAlertChange }) => {
  const [showAlertModal, setShowAlertModal] = useState(false)
  const [alertPrice, setAlertPrice] = useState('')
  const [alertType, setAlertType] = useState('above')
  const [isAlertEnabled, setIsAlertEnabled] = useState(false)

  const handleAlertSubmit = () => {
    if (alertPrice && onAlertChange) {
      onAlertChange({
        symbol: crypto.symbol,
        targetPrice: parseFloat(alertPrice),
        type: alertType,
        enabled: isAlertEnabled
      })
      setShowAlertModal(false)
    }
  }

  const getPriceChangeIcon = (change) => {
    if (change > 0) return <IconTrendingUp size={16} />
    if (change < 0) return <IconTrendingDown size={16} />
    return null
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

  return (
    <>
      <Card shadow="sm" padding="lg" radius="md" withBorder>
        <Group justify="space-between" mb="md">
          <div>
            <Text fw={600} size="lg">
              {crypto.name}
            </Text>
            <Badge variant="light" color="gray">
              {crypto.symbol}
            </Badge>
          </div>
          <Group>
            <ActionIcon
              variant="subtle"
              color={getPriceChangeColor(crypto.priceChangePercent)}
              size="lg"
            >
              {getPriceChangeIcon(crypto.priceChangePercent)}
            </ActionIcon>
            <Tooltip label="Set Price Alert">
              <ActionIcon
                variant="subtle"
                color={isAlertEnabled ? "blue" : "gray"}
                onClick={() => setShowAlertModal(true)}
                size="lg"
              >
                {isAlertEnabled ? <IconBell size={20} /> : <IconBellOff size={20} />}
              </ActionIcon>
            </Tooltip>
          </Group>
        </Group>
        
        <Text size="2xl" fw={700} mb="xs">
          {formatPrice(crypto.price)}
        </Text>
        
        <Group justify="space-between" mb="md">
          <Badge
            variant="light"
            color={getPriceChangeColor(crypto.priceChangePercent)}
          >
            {formatPercentageChange(crypto.priceChangePercent)}
          </Badge>
          <Text size="sm" c="dimmed">
            Vol: {crypto.volume?.toLocaleString() || 'N/A'}
          </Text>
        </Group>

        <Group justify="space-between" c="dimmed" size="sm">
          <Text size="xs">24h High: {formatPrice(crypto.highPrice)}</Text>
          <Text size="xs">24h Low: {formatPrice(crypto.lowPrice)}</Text>
        </Group>
      </Card>

      <Modal
        opened={showAlertModal}
        onClose={() => setShowAlertModal(false)}
        title={`Set Price Alert for ${crypto.symbol}`}
        size="sm"
      >
        <Stack>
          <Select
            label="Alert Type"
            value={alertType}
            onChange={setAlertType}
            data={[
              { value: 'above', label: 'Price goes above' },
              { value: 'below', label: 'Price goes below' }
            ]}
          />
          
          <NumberInput
            label="Target Price (USDT)"
            value={alertPrice}
            onChange={setAlertPrice}
            placeholder="Enter target price"
            precision={8}
            min={0}
            step={0.00000001}
          />
          
          <Switch
            label="Enable Alert"
            checked={isAlertEnabled}
            onChange={(event) => setIsAlertEnabled(event.currentTarget.checked)}
          />
          
          <Group justify="flex-end">
            <Button variant="outline" onClick={() => setShowAlertModal(false)}>
              Cancel
            </Button>
            <Button onClick={handleAlertSubmit} disabled={!alertPrice}>
              Set Alert
            </Button>
          </Group>
        </Stack>
      </Modal>
    </>
  )
}

export default PriceAlert
