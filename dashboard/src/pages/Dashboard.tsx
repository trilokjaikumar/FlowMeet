import { motion } from 'framer-motion';
import { Calendar, Clock, FileText, TrendingUp, Mic2, Activity } from 'lucide-react';
import { StatsCard } from '../components/StatsCard/StatsCard';
import { MeetingCard } from '../components/MeetingCard/MeetingCard';
import { Timeline } from '../components/Timeline/Timeline';
import { AudioVisualizer } from '../components/AudioVisualizer/AudioVisualizer';
import { ActivityFeed } from '../components/ActivityFeed/ActivityFeed';
import { Meeting } from '../types';
import { calculateStats, groupMeetingsByDate } from '../utils/helpers';
import './Dashboard.css';

interface DashboardProps {
  meetings: Meeting[];
  onJoinMeeting?: (meeting: Meeting) => void;
  onMeetingClick?: (meeting: Meeting) => void;
  isRecording?: boolean;
  audioLevel?: number;
}

export const Dashboard: React.FC<DashboardProps> = ({
  meetings,
  onJoinMeeting,
  onMeetingClick,
  isRecording = false,
  audioLevel = 0
}) => {
  const stats = calculateStats(meetings);
  
  const upcomingMeetings = meetings
    .filter(m => m.status === 'notStarted' && new Date(m.startDate) > new Date())
    .sort((a, b) => new Date(a.startDate).getTime() - new Date(b.startDate).getTime())
    .slice(0, 5);

  const recentMeetings = meetings
    .filter(m => m.status === 'ready' || m.status === 'processing')
    .sort((a, b) => new Date(b.startDate).getTime() - new Date(a.startDate).getTime())
    .slice(0, 3);

  // Generate activity feed from meetings
  const activities = meetings
    .filter(m => m.status !== 'notStarted')
    .map(m => {
      if (m.status === 'ready' && m.notes) {
        return {
          id: `${m.id}-notes`,
          type: 'notes_generated' as const,
          title: 'AI Notes Generated',
          description: `Notes generated for "${m.title}"`,
          timestamp: m.startDate,
          meetingId: m.id
        };
      }
      if (m.status === 'processing') {
        return {
          id: `${m.id}-processing`,
          type: 'meeting_completed' as const,
          title: 'Meeting Completed',
          description: `Processing recording for "${m.title}"`,
          timestamp: m.startDate,
          meetingId: m.id
        };
      }
      return null;
    })
    .filter(Boolean)
    .sort((a, b) => new Date(b!.timestamp).getTime() - new Date(a!.timestamp).getTime())
    .slice(0, 10);

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
            <h1 className="dashboard-title">FlowMeet Dashboard</h1>
            <p className="dashboard-subtitle">
              Your intelligent meeting assistant
            </p>
          </div>
          <div className="header-actions">
            <button className="action-button secondary">
              <Calendar size={18} />
              Sync Calendar
            </button>
            <button className="action-button primary">
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
          subtitle={`${stats.totalHoursRecorded}h recorded`}
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
            <ActivityFeed activities={activities as any} maxItems={8} />
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
            <button className="view-all-link">View All</button>
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
    </div>
  );
};
