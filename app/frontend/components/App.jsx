import React, { useState, useEffect } from 'react'
import { 
  MantineProvider, 
  createTheme, 
  AppShell, 
  Title, 
  Group, 
  Container, 
  Grid, 
  Card, 
  Text, 
  Badge, 
  LoadingOverlay,
  ActionIcon,
  useComputedColorScheme,
  useMantineColorScheme,
  Tabs,
  Stack
} from '@mantine/core'
import { IconSun, IconMoon, IconTrendingUp, IconTrendingDown, IconBell, IconChartLine } from '@tabler/icons-react'
import { Notifications } from '@mantine/notifications'

// Import our new components
import PriceAlert from './PriceAlert'
import AlertManager from './AlertManager'
import PriceTicker from './PriceTicker'

// Import services
import alertService from '../services/alertService'

// Create a dark theme
const theme = createTheme({
  primaryColor: 'blue',
  fontFamily: 'Inter, sans-serif',
  components: {
    Card: {
      defaultProps: {
        shadow: 'md',
        radius: 'md',
        withBorder: true,
      },
    },
  },
})

// Separate component for the app content to use Mantine hooks
function AppContent() {
  const [cryptoData, setCryptoData] = useState([])
  const [loading, setLoading] = useState(true)
  const [alerts, setAlerts] = useState([])
  const [activeTab, setActiveTab] = useState('prices')
  const { setColorScheme } = useMantineColorScheme()
  const computedColorScheme = useComputedColorScheme('dark')

  // Load initial data
  useEffect(() => {
    loadCryptoData()
    loadAlerts()
  }, [])

  // Load cryptocurrency data from Binance API
  const loadCryptoData = async () => {
    setLoading(true)
    try {
      // For now, using mock data until Rails API is ready
      // const data = await binanceApi.getMultiplePrices()
      
      // Mock data for development
      const mockData = [
        { 
          symbol: 'BTCUSDT', 
          name: 'Bitcoin', 
          price: 43250.50, 
          priceChange: 1081.25, 
          priceChangePercent: 2.56, 
          highPrice: 44500.00, 
          lowPrice: 42000.00, 
          volume: 1234567.89, 
          quoteVolume: 53456789012.34 
        },
        { 
          symbol: 'ETHUSDT', 
          name: 'Ethereum', 
          price: 2680.75, 
          priceChange: 47.25, 
          priceChangePercent: 1.80, 
          highPrice: 2750.00, 
          lowPrice: 2600.00, 
          volume: 987654.32, 
          quoteVolume: 2654321098.76 
        },
        { 
          symbol: 'ADAUSDT', 
          name: 'Cardano', 
          price: 0.48, 
          priceChange: -0.0024, 
          priceChangePercent: -0.50, 
          highPrice: 0.50, 
          lowPrice: 0.47, 
          volume: 1234567890.12, 
          quoteVolume: 592592592.59 
        },
        { 
          symbol: 'SOLUSDT', 
          name: 'Solana', 
          price: 98.50, 
          priceChange: 3.05, 
          priceChangePercent: 3.20, 
          highPrice: 100.00, 
          lowPrice: 95.00, 
          volume: 543210.98, 
          quoteVolume: 53456789.01 
        },
        { 
          symbol: 'DOTUSDT', 
          name: 'Polkadot', 
          price: 7.25, 
          priceChange: 0.15, 
          priceChangePercent: 2.11, 
          highPrice: 7.50, 
          lowPrice: 7.00, 
          volume: 987654.32, 
          quoteVolume: 7154321.09 
        },
        { 
          symbol: 'LINKUSDT', 
          name: 'Chainlink', 
          price: 15.80, 
          priceChange: -0.20, 
          priceChangePercent: -1.25, 
          highPrice: 16.00, 
          lowPrice: 15.50, 
          volume: 654321.09, 
          quoteVolume: 10345689.01 
        }
      ]
      
      setCryptoData(mockData)
    } catch (error) {
      console.error('Error loading crypto data:', error)
      // Fallback to empty array
      setCryptoData([])
    } finally {
      setLoading(false)
    }
  }

  // Load alerts from service
  const loadAlerts = async () => {
    try {
      const alertsData = await alertService.getAlerts()
      setAlerts(alertsData)
    } catch (error) {
      console.error('Error loading alerts:', error)
      setAlerts([])
    }
  }

  // Handle alert changes
  const handleAlertChange = async (alertData) => {
    try {
      const newAlert = await alertService.createAlert(alertData)
      setAlerts(prev => [...prev, newAlert])
    } catch (error) {
      console.error('Error creating alert:', error)
    }
  }

  const handleAlertUpdate = async (alertData) => {
    try {
      const updatedAlert = await alertService.updateAlert(alertData.id, alertData)
      setAlerts(prev => prev.map(alert => 
        alert.id === alertData.id ? updatedAlert : alert
      ))
    } catch (error) {
      console.error('Error updating alert:', error)
    }
  }

  const handleAlertDelete = async (alertId) => {
    try {
      await alertService.deleteAlert(alertId)
      setAlerts(prev => prev.filter(alert => alert.id !== alertId))
    } catch (error) {
      console.error('Error deleting alert:', error)
    }
  }

  const toggleColorScheme = () => {
    setColorScheme(computedColorScheme === 'light' ? 'dark' : 'light')
  }

  return (
    <>
      <Notifications />
      <AppShell
        header={{ height: 80 }}
        padding="md"
      >
        <AppShell.Header p="md">
          <Container size="xl">
            <Group justify="space-between" h="100%">
              <Group>
                <Title order={1} size="h3" c="blue.4">
                  🚀 Crypto Alert System
                </Title>
                <Text size="sm" c="dimmed">
                  Real-time prices & smart alerts
                </Text>
              </Group>
              <ActionIcon
                variant="default"
                size="lg"
                onClick={toggleColorScheme}
                aria-label="Toggle color scheme"
              >
                {computedColorScheme === 'light' ? <IconMoon size={20} /> : <IconSun size={20} />}
              </ActionIcon>
            </Group>
          </Container>
        </AppShell.Header>

        <AppShell.Main>
          <Container size="xl" py="xl">
            <Tabs value={activeTab} onChange={setActiveTab}>
              <Tabs.List mb="lg">
                <Tabs.Tab value="prices" leftSection={<IconChartLine size={16} />}>
                  Live Prices
                </Tabs.Tab>
                <Tabs.Tab value="alerts" leftSection={<IconBell size={16} />}>
                  Price Alerts
                </Tabs.Tab>
              </Tabs.List>

              <Tabs.Panel value="prices">
                <Grid gutter="lg">
                  <Grid.Col span={{ base: 12, lg: 8 }}>
                    <PriceTicker 
                      cryptoData={cryptoData}
                      onRefresh={loadCryptoData}
                      loading={loading}
                    />
                  </Grid.Col>
                  <Grid.Col span={{ base: 12, lg: 4 }}>
                    <AlertManager 
                      alerts={alerts}
                      onAlertAdd={handleAlertChange}
                      onAlertUpdate={handleAlertUpdate}
                      onAlertDelete={handleAlertDelete}
                    />
                  </Grid.Col>
                </Grid>
              </Tabs.Panel>

              <Tabs.Panel value="alerts">
                <Stack gap="lg">
                  <AlertManager 
                    alerts={alerts}
                    onAlertAdd={handleAlertChange}
                    onAlertUpdate={handleAlertUpdate}
                    onAlertDelete={handleAlertDelete}
                  />
                  
                  <Grid gutter="lg">
                    {cryptoData.map(crypto => (
                      <Grid.Col key={crypto.symbol} span={{ base: 12, sm: 6, md: 4 }}>
                        <PriceAlert 
                          crypto={crypto}
                          onAlertChange={handleAlertChange}
                        />
                      </Grid.Col>
                    ))}
                  </Grid>
                </Stack>
              </Tabs.Panel>
            </Tabs>
          </Container>
        </AppShell.Main>
      </AppShell>
    </>
  )
}

// Main App component that provides the MantineProvider context
function App() {
  return (
    <MantineProvider theme={theme} defaultColorScheme="dark">
      <AppContent />
    </MantineProvider>
  )
}

export default App
