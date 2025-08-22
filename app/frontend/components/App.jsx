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
  Stack,
  Alert
} from '@mantine/core'
import { IconSun, IconMoon, IconTrendingUp, IconTrendingDown, IconBell, IconChartLine, IconWifi, IconWifiOff } from '@tabler/icons-react'
import { Notifications } from '@mantine/notifications'

// Import our new components
import PriceAlert from './PriceAlert'
import AlertManager from './AlertManager'
import PriceTicker from './PriceTicker'

// Import services
import alertService from '../services/alertService'

// Import the real-time data stream hook
import useCryptoDataStream from '../hooks/useCryptoDataStream'

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
  const [alerts, setAlerts] = useState([])
  const [activeTab, setActiveTab] = useState('prices')
  const { setColorScheme } = useMantineColorScheme()
  const computedColorScheme = useComputedColorScheme('dark')

  // Use the real-time data stream hook
  const {
    cryptoData,
    isConnected,
    connectionStatus,
    lastUpdate,
    error,
    refreshData,
    hasData
  } = useCryptoDataStream()

  // Load alerts from service
  useEffect(() => {
    loadAlerts()
  }, [])

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

  const getConnectionStatusColor = () => {
    switch (connectionStatus) {
      case 'connected': return 'green'
      case 'connecting': return 'yellow'
      case 'reconnecting': return 'orange'
      case 'disconnected': return 'red'
      case 'rejected': return 'red'
      case 'error': return 'red'
      default: return 'gray'
    }
  }

  const getConnectionStatusIcon = () => {
    switch (connectionStatus) {
      case 'connected': return <IconWifi size={16} />
      case 'connecting': return <IconWifi size={16} />
      case 'reconnecting': return <IconWifi size={16} />
      case 'disconnected': return <IconWifiOff size={16} />
      case 'rejected': return <IconWifiOff size={16} />
      case 'error': return <IconWifiOff size={16} />
      default: return <IconWifiOff size={16} />
    }
  }

  const getConnectionStatusText = () => {
    switch (connectionStatus) {
      case 'connected': return 'Live Data'
      case 'connecting': return 'Connecting...'
      case 'reconnecting': return 'Reconnecting...'
      case 'disconnected': return 'Disconnected'
      case 'rejected': return 'Connection Rejected'
      case 'error': return 'Connection Error'
      default: return 'Unknown Status'
    }
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
              <Group>
                {/* Connection Status Indicator */}
                <Badge
                  variant="light"
                  color={getConnectionStatusColor()}
                  leftSection={getConnectionStatusIcon()}
                  size="sm"
                >
                  {getConnectionStatusText()}
                </Badge>
                
                <ActionIcon
                  variant="default"
                  size="lg"
                  onClick={toggleColorScheme}
                  aria-label="Toggle color scheme"
                >
                  {computedColorScheme === 'light' ? <IconMoon size={20} /> : <IconSun size={20} />}
                </ActionIcon>
              </Group>
            </Group>
          </Container>
        </AppShell.Header>

        <AppShell.Main>
          <Container size="xl" py="xl">
            {/* Connection Error Alert */}
            {error && (
              <Alert 
                color="red" 
                title="Connection Error" 
                mb="lg"
                withCloseButton
                onClose={() => {}}
              >
                {error}
              </Alert>
            )}

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
                      onRefresh={refreshData}
                      loading={!isConnected || !hasData}
                      connectionStatus={connectionStatus}
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
