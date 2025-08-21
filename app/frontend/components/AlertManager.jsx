import React, { useState } from 'react'
import {
  Card,
  Group,
  Text,
  Badge,
  ActionIcon,
  Button,
  Stack,
  ScrollArea,
  Modal,
  TextInput,
  NumberInput,
  Select,
  Switch,
  Divider
} from '@mantine/core'
import { IconBell, IconTrash, IconEdit, IconPlus, IconAlertTriangle } from '@tabler/icons-react'

const AlertManager = ({ alerts = [], onAlertAdd, onAlertUpdate, onAlertDelete }) => {
  const [showAddModal, setShowAddModal] = useState(false)
  const [editingAlert, setEditingAlert] = useState(null)
  const [newAlert, setNewAlert] = useState({
    symbol: '',
    targetPrice: '',
    type: 'above',
    enabled: true
  })

  const handleAddAlert = () => {
    if (newAlert.symbol && newAlert.targetPrice && onAlertAdd) {
      onAlertAdd({
        ...newAlert,
        targetPrice: parseFloat(newAlert.targetPrice),
        id: Date.now()
      })
      setNewAlert({ symbol: '', targetPrice: '', type: 'above', enabled: true })
      setShowAddModal(false)
    }
  }

  const handleEditAlert = () => {
    if (editingAlert && onAlertUpdate) {
      onAlertUpdate({
        ...editingAlert,
        targetPrice: parseFloat(editingAlert.targetPrice)
      })
      setEditingAlert(null)
    }
  }

  const handleDeleteAlert = (alertId) => {
    if (onAlertDelete) {
      onAlertDelete(alertId)
    }
  }

  const getAlertStatusColor = (alert) => {
    if (!alert.enabled) return 'gray'
    return alert.type === 'above' ? 'green' : 'red'
  }

  const getAlertStatusText = (alert) => {
    if (!alert.enabled) return 'Disabled'
    return alert.type === 'above' ? 'Above' : 'Below'
  }

  return (
    <>
      <Card shadow="sm" padding="lg" radius="md" withBorder>
        <Group justify="space-between" mb="md">
          <div>
            <Text fw={600} size="lg">
              Price Alerts
            </Text>
            <Text size="sm" c="dimmed">
              Manage your cryptocurrency price alerts
            </Text>
          </div>
          <Button
            leftSection={<IconPlus size={16} />}
            onClick={() => setShowAddModal(true)}
            size="sm"
          >
            Add Alert
          </Button>
        </Group>

        <ScrollArea h={300}>
          {alerts.length === 0 ? (
            <Stack align="center" py="xl" c="dimmed">
              <IconBell size={48} />
              <Text>No alerts set</Text>
              <Text size="sm">Click "Add Alert" to create your first price alert</Text>
            </Stack>
          ) : (
            <Stack gap="sm">
              {alerts.map((alert) => (
                <Card key={alert.id} shadow="xs" padding="sm" radius="sm" withBorder>
                  <Group justify="space-between">
                    <div>
                      <Group gap="xs">
                        <Text fw={500}>{alert.symbol}</Text>
                        <Badge
                          variant="light"
                          color={getAlertStatusColor(alert)}
                          size="sm"
                        >
                          {getAlertStatusText(alert)}
                        </Badge>
                        {alert.enabled && (
                          <Badge variant="dot" color="blue" size="sm">
                            Active
                          </Badge>
                        )}
                      </Group>
                      <Text size="sm" c="dimmed">
                        Alert when price goes {alert.type} ${alert.targetPrice}
                      </Text>
                    </div>
                    <Group gap="xs">
                      <ActionIcon
                        variant="subtle"
                        color="blue"
                        onClick={() => setEditingAlert(alert)}
                        size="sm"
                      >
                        <IconEdit size={16} />
                      </ActionIcon>
                      <ActionIcon
                        variant="subtle"
                        color="red"
                        onClick={() => handleDeleteAlert(alert.id)}
                        size="sm"
                      >
                        <IconTrash size={16} />
                      </ActionIcon>
                    </Group>
                  </Group>
                </Card>
              ))}
            </Stack>
          )}
        </ScrollArea>
      </Card>

      {/* Add Alert Modal */}
      <Modal
        opened={showAddModal}
        onClose={() => setShowAddModal(false)}
        title="Add Price Alert"
        size="sm"
      >
        <Stack>
          <TextInput
            label="Cryptocurrency Symbol"
            value={newAlert.symbol}
            onChange={(event) => setNewAlert({ ...newAlert, symbol: event.currentTarget.value.toUpperCase() })}
            placeholder="e.g., BTC, ETH, ADA"
            maxLength={10}
          />
          
          <Select
            label="Alert Type"
            value={newAlert.type}
            onChange={(value) => setNewAlert({ ...newAlert, type: value })}
            data={[
              { value: 'above', label: 'Price goes above' },
              { value: 'below', label: 'Price goes below' }
            ]}
          />
          
          <NumberInput
            label="Target Price (USDT)"
            value={newAlert.targetPrice}
            onChange={(value) => setNewAlert({ ...newAlert, targetPrice: value })}
            placeholder="Enter target price"
            precision={8}
            min={0}
            step={0.00000001}
          />
          
          <Switch
            label="Enable Alert"
            checked={newAlert.enabled}
            onChange={(event) => setNewAlert({ ...newAlert, enabled: event.currentTarget.checked })}
          />
          
          <Group justify="flex-end">
            <Button variant="outline" onClick={() => setShowAddModal(false)}>
              Cancel
            </Button>
            <Button 
              onClick={handleAddAlert} 
              disabled={!newAlert.symbol || !newAlert.targetPrice}
            >
              Add Alert
            </Button>
          </Group>
        </Stack>
      </Modal>

      {/* Edit Alert Modal */}
      <Modal
        opened={!!editingAlert}
        onClose={() => setEditingAlert(null)}
        title="Edit Price Alert"
        size="sm"
      >
        {editingAlert && (
          <Stack>
            <TextInput
              label="Cryptocurrency Symbol"
              value={editingAlert.symbol}
              onChange={(event) => setEditingAlert({ ...editingAlert, symbol: event.currentTarget.value.toUpperCase() })}
              maxLength={10}
            />
            
            <Select
              label="Alert Type"
              value={editingAlert.type}
              onChange={(value) => setEditingAlert({ ...editingAlert, type: value })}
              data={[
                { value: 'above', label: 'Price goes above' },
                { value: 'below', label: 'Price goes below' }
              ]}
            />
            
            <NumberInput
              label="Target Price (USDT)"
              value={editingAlert.targetPrice}
              onChange={(value) => setEditingAlert({ ...editingAlert, targetPrice: value })}
              precision={8}
              min={0}
              step={0.00000001}
            />
            
            <Switch
              label="Enable Alert"
              checked={editingAlert.enabled}
              onChange={(event) => setEditingAlert({ ...editingAlert, enabled: event.currentTarget.checked })}
            />
            
            <Group justify="flex-end">
              <Button variant="outline" onClick={() => setEditingAlert(null)}>
                Cancel
              </Button>
              <Button 
                onClick={handleEditAlert} 
                disabled={!editingAlert.symbol || !editingAlert.targetPrice}
              >
                Update Alert
              </Button>
            </Group>
          </Stack>
        )}
      </Modal>
    </>
  )
}

export default AlertManager
