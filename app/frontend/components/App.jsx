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
  useMantineColorScheme
} from '@mantine/core'
import { IconSun, IconMoon, IconTrendingUp, IconTrendingDown } from '@tabler/icons-react'
import { Notifications } from '@mantine/notifications'

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

function App() {
  const [cryptoData, setCryptoData] = useState([])
  const [loading, setLoading] = useState(true)
  const { setColorScheme } = useMantineColorScheme()
  const computedColorScheme = useComputedColorScheme('dark')

  useEffect(() => {
    // Simulate loading crypto data
    setTimeout(() => {
      setCryptoData([
        { id: 1, name: 'Bitcoin', symbol: 'BTC', price: '$43,250', change: '+2.5%', marketCap: '$845.2B' },
        { id: 2, name: 'Ethereum', symbol: 'ETH', price: '$2,680', change: '+1.8%', marketCap: '$322.1B' },
        { id: 3, name: 'Cardano', symbol: 'ADA', price: '$0.48', change: '-0.5%', marketCap: '$16.8B' },
        { id: 4, name: 'Solana', symbol: 'SOL', price: '$98.50', change: '+3.2%', marketCap: '$44.2B' }
      ])
      setLoading(false)
    }, 1000)
  }, [])

  const toggleColorScheme = () => {
    setColorScheme(computedColorScheme === 'light' ? 'dark' : 'light')
  }

  return (
    <MantineProvider theme={theme} defaultColorScheme="dark">
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
                  🚀 Crypto Tracker
                </Title>
                <Text size="sm" c="dimmed">
                  Real-time cryptocurrency data
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
            <LoadingOverlay visible={loading} />
            
            {!loading && (
              <Grid gutter="lg">
                {cryptoData.map(crypto => (
                  <Grid.Col key={crypto.id} span={{ base: 12, sm: 6, md: 4 }}>
                    <Card>
                      <Group justify="space-between" mb="md">
                        <div>
                          <Text fw={600} size="lg">
                            {crypto.name}
                          </Text>
                          <Badge variant="light" color="gray">
                            {crypto.symbol}
                          </Badge>
                        </div>
                        <ActionIcon
                          variant="subtle"
                          color={crypto.change.startsWith('+') ? 'green' : 'red'}
                          size="lg"
                        >
                          {crypto.change.startsWith('+') ? <IconTrendingUp size={20} /> : <IconTrendingDown size={20} />}
                        </ActionIcon>
                      </Group>
                      
                      <Text size="2xl" fw={700} mb="xs">
                        {crypto.price}
                      </Text>
                      
                      <Group justify="space-between">
                        <Badge
                          variant="light"
                          color={crypto.change.startsWith('+') ? 'green' : 'red'}
                        >
                          {crypto.change}
                        </Badge>
                        <Text size="sm" c="dimmed">
                          {crypto.marketCap}
                        </Text>
                      </Group>
                    </Card>
                  </Grid.Col>
                ))}
              </Grid>
            )}
          </Container>
        </AppShell.Main>
      </AppShell>
    </MantineProvider>
  )
}

export default App
