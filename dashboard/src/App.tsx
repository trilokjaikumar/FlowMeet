import { useState, useEffect, useCallback } from 'react';
import { Dashboard } from './pages/Dashboard';
import { Meeting, AppSettings } from './types';
import './styles/globals.css';

function App() {
  const [meetings, setMeetings] = useState<Meeting[]>([]);
  const [settings, setSettings] = useState<AppSettings | null>(null);
  const [isRecording, setIsRecording] = useState(false);
  const [audioLevel, setAudioLevel] = useState(0);
  const [isSyncing, setIsSyncing] = useState(false);
  const [calendarStatus, setCalendarStatus] = useState<{
    appleCalendarGranted: boolean;
    googleCalendarConnected: boolean;
  }>({ appleCalendarGranted: false, googleCalendarConnected: false });

  const sendBridgeMessage = useCallback((type: string, payload?: Record<string, unknown>) => {
    if (window.webkit?.messageHandlers?.flowmeet) {
      window.webkit.messageHandlers.flowmeet.postMessage({ type, payload });
    }
  }, []);

  const handleJoinMeeting = useCallback((meeting: Meeting) => {
    // Update local state optimistically
    setMeetings(prev =>
      prev.map(m =>
        m.id === meeting.id ? { ...m, status: 'inProgress' as const } : m
      )
    );

    sendBridgeMessage('joinMeeting', {
      meetingId: meeting.id,
      zoomUrl: meeting.zoomUrl
    });
  }, [sendBridgeMessage]);

  const handleMeetingClick = useCallback((meeting: Meeting) => {
    sendBridgeMessage('showMeetingDetail', { meetingId: meeting.id });
  }, [sendBridgeMessage]);

  const handleSyncCalendar = useCallback(() => {
    setIsSyncing(true);
    sendBridgeMessage('syncCalendar');
    // Reset syncing state after a timeout — the real update comes via flowmeetReceiveMeetings
    setTimeout(() => setIsSyncing(false), 5000);
  }, [sendBridgeMessage]);

  const handleAddMeeting = useCallback((meetingData: {
    title: string;
    startDate: string;
    duration: number;
    zoomUrl?: string;
    mode?: string;
  }) => {
    sendBridgeMessage('addMeeting', meetingData as unknown as Record<string, unknown>);
  }, [sendBridgeMessage]);

  const handleUpdateSettings = useCallback((updates: Partial<AppSettings>) => {
    sendBridgeMessage('updateSettings', updates as unknown as Record<string, unknown>);
    // Optimistically update local settings
    setSettings(prev => prev ? { ...prev, ...updates } : null);
  }, [sendBridgeMessage]);

  const handleRequestCalendarPermission = useCallback(() => {
    sendBridgeMessage('requestCalendarPermission');
  }, [sendBridgeMessage]);

  // Register global receiver functions that Swift calls via evaluateJavaScript
  useEffect(() => {
    window.flowmeetReceiveMeetings = (rawMeetings: unknown[]) => {
      setMeetings(rawMeetings as Meeting[]);
      setIsSyncing(false);
    };

    window.flowmeetReceiveSettings = (rawSettings: Record<string, unknown>) => {
      setSettings(rawSettings as unknown as AppSettings);
    };

    window.flowmeetReceiveRecordingStatus = (status: { isRecording: boolean; level: number }) => {
      setIsRecording(status.isRecording);
      setAudioLevel(status.level);
    };

    window.flowmeetReceiveCalendarStatus = (status: { appleCalendarGranted: boolean; googleCalendarConnected: boolean }) => {
      setCalendarStatus(status);
    };

    // Signal to Swift that the dashboard is ready
    sendBridgeMessage('ready');

    return () => {
      delete window.flowmeetReceiveSettings;
      delete window.flowmeetReceiveMeetings;
      delete window.flowmeetReceiveRecordingStatus;
      delete window.flowmeetReceiveCalendarStatus;
    };
  }, [sendBridgeMessage]);

  return (
    <Dashboard
      meetings={meetings}
      settings={settings}
      onJoinMeeting={handleJoinMeeting}
      onMeetingClick={handleMeetingClick}
      onSyncCalendar={handleSyncCalendar}
      onAddMeeting={handleAddMeeting}
      onUpdateSettings={handleUpdateSettings}
      onRequestCalendarPermission={handleRequestCalendarPermission}
      calendarStatus={calendarStatus}
      isRecording={isRecording}
      audioLevel={audioLevel}
      isSyncing={isSyncing}
    />
  );
}

export default App;
