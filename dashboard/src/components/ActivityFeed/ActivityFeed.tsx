import { motion } from 'framer-motion';
import { CheckCircle2, Clock, AlertCircle, Calendar, FileText, Play } from 'lucide-react';
import { formatDistance } from 'date-fns';
import { Activity } from '../../types';
import './ActivityFeed.css';

interface ActivityFeedProps {
  activities: Activity[];
  maxItems?: number;
}

const ActivityIcon = ({ type }: { type: Activity['type'] }) => {
  switch (type) {
    case 'meeting_joined':
      return <Play size={18} />;
    case 'meeting_completed':
      return <CheckCircle2 size={18} />;
    case 'notes_generated':
      return <FileText size={18} />;
    case 'meeting_scheduled':
      return <Calendar size={18} />;
    case 'error':
      return <AlertCircle size={18} />;
    default:
      return <Clock size={18} />;
  }
};

const getActivityColor = (type: Activity['type']): string => {
  switch (type) {
    case 'meeting_joined':
      return 'var(--color-accent-primary)';
    case 'meeting_completed':
      return 'var(--color-accent-success)';
    case 'notes_generated':
      return 'var(--color-accent-primary)';
    case 'meeting_scheduled':
      return 'var(--color-accent-secondary)';
    case 'error':
      return 'var(--color-accent-error)';
    default:
      return 'var(--color-text-tertiary)';
  }
};

export const ActivityFeed: React.FC<ActivityFeedProps> = ({
  activities,
  maxItems = 10
}) => {
  const displayedActivities = activities.slice(0, maxItems);

  return (
    <div className="activity-feed">
      <div className="activity-header">
        <h3 className="activity-title">Recent Activity</h3>
        <span className="activity-count">{activities.length} events</span>
      </div>

      <div className="activity-list">
        {displayedActivities.length === 0 ? (
          <div className="activity-empty">
            <Clock size={32} opacity={0.3} />
            <p>No recent activity</p>
          </div>
        ) : (
          displayedActivities.map((activity, index) => (
            <motion.div
              key={activity.id}
              className="activity-item"
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.3, delay: index * 0.05 }}
            >
              <div 
                className="activity-icon"
                style={{ color: getActivityColor(activity.type) }}
              >
                <ActivityIcon type={activity.type} />
              </div>

              <div className="activity-content">
                <div className="activity-text">
                  <h4 className="activity-item-title">{activity.title}</h4>
                  <p className="activity-description">{activity.description}</p>
                </div>
                <span className="activity-time">
                  {formatDistance(new Date(activity.timestamp), new Date(), { addSuffix: true })}
                </span>
              </div>

              <div className="activity-line" />
            </motion.div>
          ))
        )}
      </div>

      {activities.length > maxItems && (
        <div className="activity-footer">
          <button className="view-all-button">
            View all {activities.length} activities
          </button>
        </div>
      )}
    </div>
  );
};
