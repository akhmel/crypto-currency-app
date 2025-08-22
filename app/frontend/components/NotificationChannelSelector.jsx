import React, { useState, useEffect } from 'react'
import { 
  Select, 
  Group, 
  Button, 
  Text, 
  Badge, 
  ActionIcon, 
  Modal, 
  TextInput, 
  Switch, 
  Stack,
  Divider,
  Alert,
  LoadingOverlay
} from '@mantine/core'
import { 
  IconPlus, 
  IconEdit, 
  IconTrash, 
  IconTestPipe,
  IconBell,
  IconMail,
  IconBrandTelegram,
  IconFileText,
  IconDeviceMobile
} from '@tabler/icons-react'
import userNotificationService from '../services/userNotificationService'

const NotificationChannelSelector = ({ 
  selectedChannelId, 
  onChannelChange, 
  disabled = false,
  showCreateButton = true 
}) => {
  const [channels, setChannels] = useState([])
  const [loading, setLoading] = useState(false)
  const [modalOpen, setModalOpen] = useState(false)
  const [editingChannel, setEditingChannel] = useState(null)
  const [formData, setFormData] = useState({
    channelType: '',
    name: '',
    description: '',
    enabled: true,
    emailAddress: '',
    telegramChatId: '',
    telegramBotToken: '',
    logFilePath: '',
    osNotificationSettings: '',
    sound: true,
    duration: 5000,
    htmlFormat: true,
    frequency: 'immediate',
    subjectTemplate: '🚨 Crypto Alert: {symbol} {alert_type} ${target_price}',
    parseMode: 'HTML',
    disableWebPagePreview: false,
    logLevel: 'INFO',
    maxFileSize: '10MB',
    rotation: 'daily',
    priority: 'normal',
    timeout: 5000
  })
  const [errors, setErrors] = useState({})

  useEffect(() => {
    loadChannels()
  }, [])

  const loadChannels = async () => {
    setLoading(true)
    try {
      const data = await userNotificationService.getEnabledNotificationChannels()
      setChannels(userNotificationService.parseChannelsFromAPI(data))
    } catch (error) {
      console.error('Error loading channels:', error)
    } finally {
      setLoading(false)
    }
  }

  const openModal = (channel = null) => {
    if (channel) {
      setEditingChannel(channel)
      setFormData({
        channelType: channel.channelType,
        name: channel.name || '',
        description: channel.description || '',
        enabled: channel.enabled,
        emailAddress: channel.emailAddress || '',
        telegramChatId: channel.telegramChatId || '',
        telegramBotToken: channel.telegramBotToken || '',
        logFilePath: channel.logFilePath || '',
        osNotificationSettings: channel.osNotificationSettings || '',
        sound: channel.sound !== undefined ? channel.sound : true,
        duration: channel.duration || 5000,
        htmlFormat: channel.htmlFormat !== undefined ? channel.htmlFormat : true,
        frequency: channel.frequency || 'immediate',
        subjectTemplate: channel.subjectTemplate || '🚨 Crypto Alert: {symbol} {alert_type} ${target_price}',
        parseMode: channel.parseMode || 'HTML',
        disableWebPagePreview: channel.disableWebPagePreview || false,
        logLevel: channel.logLevel || 'INFO',
        maxFileSize: channel.maxFileSize || '10MB',
        rotation: channel.rotation || 'daily',
        priority: channel.priority || 'normal',
        timeout: channel.timeout || 5000
      })
    } else {
      setEditingChannel(null)
      setFormData({
        channelType: '',
        name: '',
        description: '',
        enabled: true,
        emailAddress: '',
        telegramChatId: '',
        telegramBotToken: '',
        logFilePath: '',
        osNotificationSettings: '',
        sound: true,
        duration: 5000,
        htmlFormat: true,
        frequency: 'immediate',
        subjectTemplate: '🚨 Crypto Alert: {symbol} {alert_type} ${target_price}',
        parseMode: 'HTML',
        disableWebPagePreview: false,
        logLevel: 'INFO',
        maxFileSize: '10MB',
        rotation: 'daily',
        priority: 'normal',
        timeout: channel.timeout || 5000
      })
    }
    setErrors({})
    setModalOpen(true)
  }

  const closeModal = () => {
    setModalOpen(false)
    setEditingChannel(null)
    setFormData({})
    setErrors({})
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    
    // Validate form
    const validationErrors = userNotificationService.validateChannelData(formData)
    if (validationErrors.length > 0) {
      setErrors({ general: validationErrors.join(', ') })
      return
    }

    try {
      if (editingChannel) {
        await userNotificationService.updateNotificationChannel(editingChannel.id, formData)
      } else {
        const newChannel = await userNotificationService.createNotificationChannel(formData)
        // Auto-select the newly created channel
        onChannelChange(newChannel.id)
      }
      closeModal()
      loadChannels()
    } catch (error) {
      setErrors({ general: userNotificationService.handleApiError(error) })
    }
  }

  const handleDelete = async (channelId) => {
    if (window.confirm('Are you sure you want to delete this notification channel?')) {
      try {
        await userNotificationService.deleteNotificationChannel(channelId)
        if (selectedChannelId === channelId) {
          onChannelChange(null)
        }
        loadChannels()
      } catch (error) {
        console.error('Error deleting channel:', error)
      }
    }
  }

  const handleTest = async (channelId) => {
    try {
      await userNotificationService.testNotificationChannel(channelId)
      alert('Test notification sent successfully!')
    } catch (error) {
      alert(`Error testing notification: ${userNotificationService.handleApiError(error)}`)
    }
  }

  const getChannelIcon = (channelType) => {
    return userNotificationService.getChannelIcon(channelType)
  }

  const getChannelTypeLabel = (channelType) => {
    const labels = {
      browser: 'Browser',
      email: 'Email',
      telegram: 'Telegram',
      log_file: 'Log File',
      os_notification: 'OS Notification'
    }
    return labels[channelType] || channelType
  }

  const renderChannelSpecificFields = () => {
    switch (formData.channelType) {
      case 'email':
        return (
          <Stack spacing="md">
            <TextInput
              label="Email Address"
              placeholder="user@example.com"
              value={formData.emailAddress}
              onChange={(e) => setFormData({ ...formData, emailAddress: e.target.value })}
              required
            />
            <Switch
              label="HTML Format"
              checked={formData.htmlFormat}
              onChange={(e) => setFormData({ ...formData, htmlFormat: e.currentTarget.checked })}
            />
            <Select
              label="Frequency"
              data={[
                { value: 'immediate', label: 'Immediate' },
                { value: 'hourly', label: 'Hourly' },
                { value: 'daily', label: 'Daily' }
              ]}
              value={formData.frequency}
              onChange={(value) => setFormData({ ...formData, frequency: value })}
            />
            <TextInput
              label="Subject Template"
              placeholder="🚨 Crypto Alert: {symbol} {alert_type} ${target_price}"
              value={formData.subjectTemplate}
              onChange={(e) => setFormData({ ...formData, subjectTemplate: e.target.value })}
            />
          </Stack>
        )

      case 'telegram':
        return (
          <Stack spacing="md">
            <TextInput
              label="Telegram Chat ID"
              placeholder="123456789"
              value={formData.telegramChatId}
              onChange={(e) => setFormData({ ...formData, telegramChatId: e.target.value })}
              required
            />
            <TextInput
              label="Bot Token"
              placeholder="123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
              value={formData.telegramBotToken}
              onChange={(e) => setFormData({ ...formData, telegramBotToken: e.target.value })}
              required
            />
            <Select
              label="Parse Mode"
              data={[
                { value: 'HTML', label: 'HTML' },
                { value: 'Markdown', label: 'Markdown' }
              ]}
              value={formData.parseMode}
              onChange={(value) => setFormData({ ...formData, parseMode: value })}
            />
            <Switch
              label="Disable Web Page Preview"
              checked={formData.disableWebPagePreview}
              onChange={(e) => setFormData({ ...formData, disableWebPagePreview: e.currentTarget.checked })}
            />
          </Stack>
        )

      case 'log_file':
        return (
          <Stack spacing="md">
            <TextInput
              label="Log File Path"
              placeholder="/var/log/crypto-alerts.log"
              value={formData.logFilePath}
              onChange={(e) => setFormData({ ...formData, logFilePath: e.target.value })}
              required
            />
            <Select
              label="Log Level"
              data={[
                { value: 'DEBUG', label: 'DEBUG' },
                { value: 'INFO', label: 'INFO' },
                { value: 'WARN', label: 'WARN' },
                { value: 'ERROR', label: 'ERROR' }
              ]}
              value={formData.logLevel}
              onChange={(value) => setFormData({ ...formData, logLevel: value })}
            />
            <TextInput
              label="Max File Size"
              placeholder="10MB"
              value={formData.maxFileSize}
              onChange={(e) => setFormData({ ...formData, maxFileSize: e.target.value })}
            />
            <Select
              label="Rotation"
              data={[
                { value: 'daily', label: 'Daily' },
                { value: 'weekly', label: 'Weekly' },
                { value: 'monthly', label: 'Monthly' }
              ]}
              value={formData.rotation}
              onChange={(value) => setFormData({ ...formData, rotation: value })}
            />
          </Stack>
        )

      case 'os_notification':
        return (
          <Stack spacing="md">
            <Switch
              label="Sound"
              checked={formData.sound}
              onChange={(e) => setFormData({ ...formData, sound: e.currentTarget.checked })}
            />
            <Select
              label="Priority"
              data={[
                { value: 'low', label: 'Low' },
                { value: 'normal', label: 'Normal' },
                { value: 'high', label: 'High' }
              ]}
              value={formData.priority}
              onChange={(value) => setFormData({ ...formData, priority: value })}
            />
            <TextInput
              label="Timeout (ms)"
              type="number"
              value={formData.timeout}
              onChange={(e) => setFormData({ ...formData, timeout: parseInt(e.target.value) })}
            />
          </Stack>
        )

      case 'browser':
        return (
          <Stack spacing="md">
            <Switch
              label="Sound"
              checked={formData.sound}
              onChange={(e) => setFormData({ ...formData, sound: e.currentTarget.checked })}
            />
            <TextInput
              label="Duration (ms)"
              type="number"
              value={formData.duration}
              onChange={(e) => setFormData({ ...formData, duration: parseInt(e.target.value) })}
            />
            <TextInput
              label="Icon URL (optional)"
              placeholder="https://example.com/icon.png"
              value={formData.icon || ''}
              onChange={(e) => setFormData({ ...formData, icon: e.target.value })}
            />
          </Stack>
        )

      default:
        return null
    }
  }

  const selectedChannel = channels.find(ch => ch.id === selectedChannelId)

  return (
    <div>
      <Group position="apart" mb="xs">
        <Text size="sm" weight={500}>Notification Channel</Text>
        {showCreateButton && (
          <Button 
            size="xs" 
            leftIcon={<IconPlus size={14} />} 
            onClick={() => openModal()}
            variant="light"
            compact
          >
            Add New
          </Button>
        )}
      </Group>

      <Select
        placeholder="Select notification channel"
        data={channels.map(channel => ({
          value: channel.id.toString(),
          label: `${getChannelIcon(channel.channelType)} ${channel.name || getChannelTypeLabel(channel.channelType)}`,
          channel: channel
        }))}
        value={selectedChannelId?.toString() || ''}
        onChange={(value) => onChannelChange(value ? parseInt(value) : null)}
        disabled={disabled}
        searchable
        clearable
        nothingFound="No channels found"
      />

      {selectedChannel && (
        <Group position="apart" mt="xs">
          <Group spacing="xs">
            <Badge 
              size="sm" 
              color={selectedChannel.enabled ? 'green' : 'red'}
              variant="light"
            >
              {selectedChannel.enabled ? 'Active' : 'Inactive'}
            </Badge>
            <Text size="xs" color="dimmed">
              {selectedChannel.channelDescription}
            </Text>
          </Group>
          
          <Group spacing={4}>
            <ActionIcon
              size="xs"
              color="blue"
              onClick={() => handleTest(selectedChannel.id)}
              title="Test"
            >
              <IconTestPipe size={12} />
            </ActionIcon>
            <ActionIcon
              size="xs"
              color="yellow"
              onClick={() => openModal(selectedChannel)}
              title="Edit"
            >
              <IconEdit size={12} />
            </ActionIcon>
            <ActionIcon
              size="xs"
              color="red"
              onClick={() => handleDelete(selectedChannel.id)}
              title="Delete"
            >
              <IconTrash size={12} />
            </ActionIcon>
          </Group>
        </Group>
      )}

      <Modal
        opened={modalOpen}
        onClose={closeModal}
        title={editingChannel ? 'Edit Notification Channel' : 'Add Notification Channel'}
        size="lg"
      >
        <form onSubmit={handleSubmit}>
          <Stack spacing="md">
            {errors.general && (
              <Alert color="red" title="Error">
                {errors.general}
              </Alert>
            )}

            <Select
              label="Channel Type"
              placeholder="Select channel type"
              data={[
                { value: 'browser', label: '🌐 Browser Notifications' },
                { value: 'email', label: '📧 Email Notifications' },
                { value: 'telegram', label: '📱 Telegram Notifications' },
                { value: 'log_file', label: '📝 Log File' },
                { value: 'os_notification', label: '🔔 OS Notifications' }
              ]}
              value={formData.channelType}
              onChange={(value) => setFormData({ ...formData, channelType: value })}
              required
            />

            <TextInput
              label="Name (optional)"
              placeholder="My Email Channel"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
            />

            <TextInput
              label="Description (optional)"
              placeholder="Description of this notification channel"
              multiline
              rows={4}
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
            />

            <Switch
              label="Enabled"
              checked={formData.enabled}
              onChange={(e) => setFormData({ ...formData, enabled: e.currentTarget.checked })}
            />

            {formData.channelType && (
              <>
                <Divider label="Channel Settings" labelPosition="center" />
                {renderChannelSpecificFields()}
              </>
            )}

            <Group position="right" mt="md">
              <Button variant="outline" onClick={closeModal}>
                Cancel
              </Button>
              <Button type="submit" color="blue">
                {editingChannel ? 'Update' : 'Create'}
              </Button>
            </Group>
          </Stack>
        </form>
      </Modal>
    </div>
  )
}

export default NotificationChannelSelector
