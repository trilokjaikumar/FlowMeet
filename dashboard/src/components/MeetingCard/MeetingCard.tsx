import { motion } from 'framer-motion';
import { Clock, Calendar, Play, CheckCircle2, AlertCircle, Loader } from 'lucide-react';
import { Meeting } from '../../types';
import { 
  formatMeetingTime, 
  formatMeetingDate, 
  getTimeUntilMeeting, 
  formatDuration,
  getStatusColor,
  getStatusLabel,
  getModeLabel,
  truncateText
} from '../../utils/helpers';
import './MeetingCard.css';

interface MeetingCardProps {
  meeting: Meeting;
  onJoin?: (meeting: Meeting) => void;
  onClick?: (meeting: Meeting) => void;
  delay?: number;
}

const StatusIcon = ({ status }: { status: string }) => {
  switch (status) {
    case 'inProgress':
      return <Loader className="animate-pulse" size={16} />;
    case 'ready':
      return <CheckCircle2 size={16} />;
    case 'failed':
      return <AlertCircle size={16} />;
    default:
      return <Clock size={16} />;
  }
};

export const MeetingCard: React.FC<MeetingCardProps> = ({
  meeting,
  onJoin,
  onClick,
  delay = 0
}) => {
  const isUpcoming = meeting.status === 'notStarted';
  const isActive = meeting.status === 'inProgress';
  const timeUntil = isUpcoming ? getTimeUntilMeeting(meeting.startDate) : null;

  return (
    <motion.div
      className={`meeting-card ${isActive ? 'active' : ''}`}
      initial={{ opacity: 0, x: -20 }}
      animate={{ opacity: 1, x: 0 }}
      transition={{ duration: 0.3, delay }}
      whileHover={{ scale: 1.02 }}
      onClick={() => onClick?.(meeting)}
    >
      {isActive && <div className="meeting-card-pulse" />}
      
      <div className="meeting-card-header">
        <div className="meeting-card-time">
          <Calendar size={14} />
          <span>{formatMeetingDate(meeting.startDate)}</span>
          <span className="time-separator">•</span>
          <span>{formatMeetingTime(meeting.startDate)}</span>
        </div>
        
        <div className="meeting-card-badges">
          <span className={`badge badge-${meeting.mode}`}>
            {getModeLabel(meeting.mode)}
          </span>
          <span 
            className="badge badge-status"
            style={{ 
              background: `${getStatusColor(meeting.status)}15`,
              color: getStatusColor(meeting.status)
            }}
          >
            <StatusIcon status={meeting.status} />
            {getStatusLabel(meeting.status)}
          </span>
        </div>
      </div>

      <div className="meeting-card-content">
        <h3 className="meeting-card-title">{truncateText(meeting.title, 60)}</h3>
        
        <div className="meeting-card-meta">
          <span className="meta-item">
            <Clock size={14} />
            {formatDuration(meeting.duration)}
          </span>
          
          {timeUntil && (
            <span className={`meta-item countdown ${timeUntil === 'Starting now' ? 'urgent' : ''}`}>
              {timeUntil}
            </span>
          )}
        </div>
      </div>

      {isUpcoming && onJoin && (
        <motion.button
          className="meeting-card-join"
          onClick={(e) => {
            e.stopPropagation();
            onJoin(meeting);
          }}
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
        >
          <Play size={16} fill="currentColor" />
          Join Now
        </motion.button>
      )}

      {meeting.notes && (
        <div className="meeting-card-notes-indicator">
          <span className="notes-dot" />
          AI Notes Available
        </div>
      )}
    </motion.div>
  );
};
