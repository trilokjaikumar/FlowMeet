import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Calendar, Clock, FileText, TrendingUp, Mic2, X, Loader, RefreshCw, Check, ExternalLink, Apple } from 'lucide-react';
import { StatsCard } from '../components/StatsCard/StatsCard';
import { MeetingCard } from '../components/MeetingCard/MeetingCard';
import { Timeline } from '../components/Timeline/Timeline';
import { AudioVisualizer } from '../components/AudioVisualizer/AudioVisualizer';
import { ActivityFeed } from '../components/ActivityFeed/ActivityFeed';
import { Meeting, AppSettings, Activity } from '../types';
import { calculateStats } from '../utils/helpers';
import './Dashboard.css';

interface DashboardProps {
  meetings: Meeting[];
  settings: AppSettings | null;
  onJoinMeeting?: (meeting: Meeting) => void;
  onMeetingClick?: (meeting: Meeting) => void;
  onSyncCalendar?: () => void;
  onAddMeeting?: (data: {
    title: string;
    startDate: string;
    duration: number;
    zoomUrl?: string;
    mode?: string;
  }) => void;
  onUpdateSettings?: (updates: Partial<AppSettings>) => void;
  onRequestCalendarPermission?: () => void;
  calendarStatus?: { appleCalendarGranted: boolean; googleCalendarConnected: boolean };
  isRecording?: boolean;
  audioLevel?: number;
  isSyncing?: boolean;
}

export const Dashboard: React.FC<DashboardProps> = ({
  meetings,
  settings,
  onJoinMeeting,
  onMeetingClick,
  onSyncCalendar,
  onAddMeeting,
  onRequestCalendarPermission,
  calendarStatus,
  isRecording = false,
  audioLevel = 0,
  isSyncing = false
}) => {
  const [showAddMeeting, setShowAddMeeting] = useState(false);
  const [showSyncCalendar, setShowSyncCalendar] = useState(false);
  const [syncMessage, setSyncMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);
  const [newMeeting, setNewMeeting] = useState({
    title: '',
    date: '',
    time: '',
    duration: 60,
    zoomUrl: '',
  });

  const stats = calculateStats(meetings);

  const upcomingMeetings = meetings
    .filter(m => m.status === 'notStarted' && new Date(m.startDate) > new Date())
    .sort((a, b) => new Date(a.startDate).getTime() - new Date(b.startDate).getTime())
    .slice(0, 5);

  const activeMeetings = meetings.filter(m => m.status === 'inProgress');

  const recentMeetings = meetings
    .filter(m => m.status === 'ready' || m.status === 'processing')
    .sort((a, b) => new Date(b.startDate).getTime() - new Date(a.startDate).getTime())
    .slice(0, 3);

  // Generate activity feed from real meeting data
  const activities: Activity[] = meetings
    .filter(m => m.status !== 'notStarted')
    .flatMap(m => {
      const items: Activity[] = [];

      if (m.status === 'inProgress') {
        items.push({
          id: `${m.id}-joined`,
          type: 'meeting_joined',
          title: 'Meeting Joined',
          description: `Joined "${m.title}"`,
          timestamp: m.startDate,
          meetingId: m.id
        });
      }
      if (m.status === 'ready' && m.notes) {
        items.push({
          id: `${m.id}-notes`,
          type: 'notes_generated',
          title: 'AI Notes Generated',
          description: `Notes ready for "${m.title}"`,
          timestamp: m.startDate,
          meetingId: m.id
        });
      }
      if (m.status === 'processing') {
        items.push({
          id: `${m.id}-processing`,
          type: 'meeting_completed',
          title: 'Meeting Completed',
          description: `Processing recording for "${m.title}"`,
          timestamp: m.startDate,
          meetingId: m.id
        });
      }
      if (m.status === 'ready' && !m.notes) {
        items.push({
          id: `${m.id}-completed`,
          type: 'meeting_completed',
          title: 'Meeting Completed',
          description: `"${m.title}" finished`,
          timestamp: m.startDate,
          meetingId: m.id
        });
      }
      if (m.status === 'failed') {
        items.push({
          id: `${m.id}-failed`,
          type: 'error',
          title: 'Processing Failed',
          description: `Failed to process "${m.title}"`,
          timestamp: m.startDate,
          meetingId: m.id
        });
      }

      return items;
    })
    .sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime())
    .slice(0, 10);

  const handleSubmitMeeting = () => {
    if (!newMeeting.title.trim() || !newMeeting.date || !newMeeting.time) return;

    const startDate = new Date(`${newMeeting.date}T${newMeeting.time}`).toISOString();

    onAddMeeting?.({
      title: newMeeting.title.trim(),
      startDate,
      duration: newMeeting.duration * 60,
      zoomUrl: newMeeting.zoomUrl.trim() || undefined,
      mode: settings?.defaultMode,
    });

    // Reset form and close modal
    setNewMeeting({ title: '', date: '', time: '', duration: 60, zoomUrl: '' });
    setShowAddMeeting(false);
  };

  return (
    <div className="dashboard">
      {/* Header */}
      <motion.header
        className="dashboard-header"
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
      >
        <div className="header-content">
          <div className="header-text">
            <h1 className="dashboard-title">FlowMeet</h1>
            <p className="dashboard-subtitle">
              {activeMeetings.length > 0
                ? `${activeMeetings.length} meeting${activeMeetings.length > 1 ? 's' : ''} in progress`
                : 'Your intelligent meeting assistant'}
            </p>
          </div>
          <div className="header-actions">
            <button
              className="action-button secondary"
              onClick={() => setShowSyncCalendar(true)}
            >
              {isSyncing ? (
                <Loader size={18} className="animate-spin" />
              ) : (
                <Calendar size={18} />
              )}
              {isSyncing ? 'Syncing...' : 'Sync Calendar'}
            </button>
            <button
              className="action-button primary"
              onClick={() => setShowAddMeeting(true)}
            >
              <Mic2 size={18} />
              New Meeting
            </button>
          </div>
        </div>
      </motion.header>

      {/* Stats Grid */}
      <section className="stats-grid">
        <StatsCard
          title="Total Meetings"
          value={stats.totalMeetings}
          subtitle="All time"
          icon={Calendar}
          gradient="gradient-blue"
          delay={0.1}
        />
        <StatsCard
          title="Upcoming"
          value={stats.upcomingMeetings}
          subtitle="Scheduled"
          icon={Clock}
          gradient="gradient-purple"
          delay={0.2}
        />
        <StatsCard
          title="Completed Today"
          value={stats.completedToday}
          subtitle="Meetings"
          icon={TrendingUp}
          gradient="gradient-green"
          delay={0.3}
        />
        <StatsCard
          title="AI Notes"
          value={stats.notesGenerated}
          subtitle={stats.totalHoursRecorded > 0 ? `${stats.totalHoursRecorded}h recorded` : 'No recordings yet'}
          icon={FileText}
          gradient="gradient-orange"
          delay={0.4}
        />
      </section>

      {/* Timeline */}
      <motion.section
        className="timeline-section"
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.5 }}
      >
        <Timeline meetings={meetings} />
      </motion.section>

      {/* Main Content Grid */}
      <div className="content-grid">
        {/* Upcoming Meetings */}
        <motion.section
          className="meetings-section"
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.5, delay: 0.6 }}
        >
          <div className="section-header">
            <h2 className="section-title">Upcoming Meetings</h2>
            <span className="section-count">{upcomingMeetings.length}</span>
          </div>

          <div className="meetings-list">
            {upcomingMeetings.length === 0 ? (
              <div className="empty-state">
                <Calendar size={48} opacity={0.2} />
                <p>No upcoming meetings</p>
                <p style={{ fontSize: '0.875rem', opacity: 0.6, marginTop: '4px' }}>
                  Sync your calendar or add a meeting to get started
                </p>
              </div>
            ) : (
              upcomingMeetings.map((meeting, index) => (
                <MeetingCard
                  key={meeting.id}
                  meeting={meeting}
                  onJoin={onJoinMeeting}
                  onClick={onMeetingClick}
                  delay={0.7 + index * 0.05}
                />
              ))
            )}
          </div>
        </motion.section>

        {/* Sidebar */}
        <div className="sidebar">
          {/* Audio Visualizer */}
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.5, delay: 0.7 }}
          >
            <AudioVisualizer
              isRecording={isRecording}
              level={audioLevel}
              showWaveform={true}
            />
          </motion.div>

          {/* Activity Feed */}
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.5, delay: 0.8 }}
          >
            <ActivityFeed activities={activities} maxItems={8} />
          </motion.div>
        </div>
      </div>

      {/* Recent Meetings */}
      {recentMeetings.length > 0 && (
        <motion.section
          className="recent-section"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.9 }}
        >
          <div className="section-header">
            <h2 className="section-title">Recent Meetings with Notes</h2>
          </div>

          <div className="recent-grid">
            {recentMeetings.map((meeting, index) => (
              <MeetingCard
                key={meeting.id}
                meeting={meeting}
                onClick={onMeetingClick}
                delay={1.0 + index * 0.05}
              />
            ))}
          </div>
        </motion.section>
      )}

      {/* Add Meeting Modal */}
      <AnimatePresence>
        {showAddMeeting && (
          <motion.div
            className="modal-overlay"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setShowAddMeeting(false)}
          >
            <motion.div
              className="modal-content"
              initial={{ opacity: 0, scale: 0.95, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 20 }}
              transition={{ duration: 0.2 }}
              onClick={e => e.stopPropagation()}
            >
              <div className="modal-header">
                <h2 className="modal-title">New Meeting</h2>
                <button className="modal-close" onClick={() => setShowAddMeeting(false)}>
                  <X size={20} />
                </button>
              </div>

              <div className="modal-body">
                <div className="form-group">
                  <label className="form-label">Meeting Title</label>
                  <input
                    type="text"
                    className="form-input"
                    placeholder="e.g. Weekly Team Sync"
                    value={newMeeting.title}
                    onChange={e => setNewMeeting(prev => ({ ...prev, title: e.target.value }))}
                    autoFocus
                  />
                </div>

                <div className="form-row">
                  <div className="form-group">
                    <label className="form-label">Date</label>
                    <input
                      type="date"
                      className="form-input"
                      value={newMeeting.date}
                      onChange={e => setNewMeeting(prev => ({ ...prev, date: e.target.value }))}
                    />
                  </div>
                  <div className="form-group">
                    <label className="form-label">Time</label>
                    <input
                      type="time"
                      className="form-input"
                      value={newMeeting.time}
                      onChange={e => setNewMeeting(prev => ({ ...prev, time: e.target.value }))}
                    />
                  </div>
                </div>

                <div className="form-row">
                  <div className="form-group">
                    <label className="form-label">Duration (minutes)</label>
                    <select
                      className="form-input"
                      value={newMeeting.duration}
                      onChange={e => setNewMeeting(prev => ({ ...prev, duration: Number(e.target.value) }))}
                    >
                      <option value={15}>15 min</option>
                      <option value={30}>30 min</option>
                      <option value={45}>45 min</option>
                      <option value={60}>1 hour</option>
                      <option value={90}>1.5 hours</option>
                      <option value={120}>2 hours</option>
                    </select>
                  </div>
                </div>

                <div className="form-group">
                  <label className="form-label">Zoom URL (optional)</label>
                  <input
                    type="url"
                    className="form-input"
                    placeholder="https://zoom.us/j/..."
                    value={newMeeting.zoomUrl}
                    onChange={e => setNewMeeting(prev => ({ ...prev, zoomUrl: e.target.value }))}
                  />
                </div>
              </div>

              <div className="modal-footer">
                <button
                  className="action-button secondary"
                  onClick={() => setShowAddMeeting(false)}
                >
                  Cancel
                </button>
                <button
                  className="action-button primary"
                  onClick={handleSubmitMeeting}
                  disabled={!newMeeting.title.trim() || !newMeeting.date || !newMeeting.time}
                >
                  Add Meeting
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Sync Calendar Modal */}
      <AnimatePresence>
        {showSyncCalendar && (
          <motion.div
            className="modal-overlay"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => { setShowSyncCalendar(false); setSyncMessage(null); }}
          >
            <motion.div
              className="modal-content"
              initial={{ opacity: 0, scale: 0.95, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 20 }}
              transition={{ duration: 0.2 }}
              onClick={e => e.stopPropagation()}
            >
              <div className="modal-header">
                <h2 className="modal-title">Calendar Sources</h2>
                <button className="modal-close" onClick={() => { setShowSyncCalendar(false); setSyncMessage(null); }}>
                  <X size={20} />
                </button>
              </div>

              <div className="modal-body">
                <p className="sync-description">
                  Connect your calendars to automatically import meetings with Zoom links.
                </p>

                {/* Apple Calendar */}
                <div className="calendar-source-card">
                  <div className="calendar-source-info">
                    <div className="calendar-source-icon apple">
                      <Apple size={20} />
                    </div>
                    <div>
                      <div className="calendar-source-name">Apple Calendar</div>
                      <div className="calendar-source-detail">
                        {settings?.appleCalendarEnabled && calendarStatus?.appleCalendarGranted
                          ? 'Connected — syncing events'
                          : settings?.appleCalendarEnabled && !calendarStatus?.appleCalendarGranted
                          ? 'Permission required — toggle to request'
                          : 'Requires macOS Calendar permission'}
                      </div>
                    </div>
                  </div>
                  <button
                    className={`calendar-toggle ${settings?.appleCalendarEnabled ? 'active' : ''}`}
                    onClick={() => {
                      if (settings?.appleCalendarEnabled) {
                        // Turning OFF — just update the setting
                        onUpdateSettings?.({ appleCalendarEnabled: false });
                      } else {
                        // Turning ON — request permission from macOS, then enable
                        onRequestCalendarPermission?.();
                        onUpdateSettings?.({ appleCalendarEnabled: true });
                      }
                    }}
                  >
                    <div className="toggle-knob" />
                  </button>
                </div>

                {/* Google Calendar */}
                <div className="calendar-source-card" style={{ opacity: 0.6 }}>
                  <div className="calendar-source-info">
                    <div className="calendar-source-icon google">
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                        <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z" fill="#4285F4"/>
                        <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
                        <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18A10.96 10.96 0 0 0 1 12c0 1.77.42 3.45 1.18 4.93l3.66-2.84z" fill="#FBBC05"/>
                        <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
                      </svg>
                    </div>
                    <div>
                      <div className="calendar-source-name">Google Calendar</div>
                      <div className="calendar-source-detail">Coming soon</div>
                    </div>
                  </div>
                  <button
                    className="action-button-sm"
                    disabled
                    style={{ opacity: 0.5, cursor: 'not-allowed' }}
                  >
                    <ExternalLink size={14} />
                    Connect
                  </button>
                </div>

                {/* Sync message */}
                <AnimatePresence>
                  {syncMessage && (
                    <motion.div
                      className={`sync-message ${syncMessage.type}`}
                      initial={{ opacity: 0, height: 0 }}
                      animate={{ opacity: 1, height: 'auto' }}
                      exit={{ opacity: 0, height: 0 }}
                    >
                      {syncMessage.type === 'success' ? <Check size={16} /> : null}
                      {syncMessage.text}
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>

              <div className="modal-footer">
                <button
                  className="action-button secondary"
                  onClick={() => { setShowSyncCalendar(false); setSyncMessage(null); }}
                >
                  Done
                </button>
                <button
                  className="action-button primary"
                  onClick={() => {
                    onSyncCalendar?.();
                    setSyncMessage({ type: 'success', text: 'Calendar sync started. New meetings will appear shortly.' });
                    setTimeout(() => setSyncMessage(null), 4000);
                  }}
                  disabled={isSyncing || !settings?.appleCalendarEnabled}
                >
                  {isSyncing ? (
                    <Loader size={16} className="animate-spin" />
                  ) : (
                    <RefreshCw size={16} />
                  )}
                  {isSyncing ? 'Syncing...' : 'Sync Now'}
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};
