import { motion } from 'framer-motion';
import { Meeting } from '../../types';
import { formatMeetingTime, formatDuration, getMeetingProgress } from '../../utils/helpers';
import './Timeline.css';

interface TimelineProps {
  meetings: Meeting[];
}

export const Timeline: React.FC<TimelineProps> = ({ meetings }) => {
  const todayMeetings = meetings
    .filter(m => {
      const today = new Date();
      const meetingDate = new Date(m.startDate);
      return meetingDate.toDateString() === today.toDateString();
    })
    .sort((a, b) => new Date(a.startDate).getTime() - new Date(b.startDate).getTime());

  if (todayMeetings.length === 0) {
    return (
      <div className="timeline-empty">
        <div className="empty-icon">📅</div>
        <p>No meetings scheduled for today</p>
      </div>
    );
  }

  const startOfDay = new Date();
  startOfDay.setHours(8, 0, 0, 0);
  const endOfDay = new Date();
  endOfDay.setHours(18, 0, 0, 0);

  const dayDuration = endOfDay.getTime() - startOfDay.getTime();

  const getTimelinePosition = (dateString: string): number => {
    const meetingTime = new Date(dateString).getTime();
    const position = ((meetingTime - startOfDay.getTime()) / dayDuration) * 100;
    return Math.max(0, Math.min(100, position));
  };

  const getMeetingWidth = (duration: number): number => {
    const durationMs = duration * 1000;
    const width = (durationMs / dayDuration) * 100;
    return Math.max(2, Math.min(100, width));
  };

  const currentTimePosition = getTimelinePosition(new Date().toISOString());

  return (
    <div className="timeline-container">
      <div className="timeline-header">
        <h3 className="timeline-title">Today's Schedule</h3>
        <div className="timeline-legend">
          <div className="legend-item">
            <span className="legend-dot upcoming" />
            <span>Upcoming</span>
          </div>
          <div className="legend-item">
            <span className="legend-dot active" />
            <span>Active</span>
          </div>
          <div className="legend-item">
            <span className="legend-dot completed" />
            <span>Completed</span>
          </div>
        </div>
      </div>

      <div className="timeline-track">
        {/* Time markers */}
        <div className="timeline-markers">
          {[8, 10, 12, 14, 16, 18].map(hour => (
            <div 
              key={hour}
              className="timeline-marker"
              style={{ left: `${((hour - 8) / 10) * 100}%` }}
            >
              <span className="marker-time">
                {hour > 12 ? `${hour - 12}pm` : `${hour}am`}
              </span>
            </div>
          ))}
        </div>

        {/* Current time indicator */}
        {currentTimePosition >= 0 && currentTimePosition <= 100 && (
          <motion.div
            className="timeline-current"
            style={{ left: `${currentTimePosition}%` }}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.5 }}
          >
            <div className="current-time-line" />
            <div className="current-time-dot" />
          </motion.div>
        )}

        {/* Meeting blocks */}
        <div className="timeline-meetings">
          {todayMeetings.map((meeting, index) => {
            const position = getTimelinePosition(meeting.startDate);
            const width = getMeetingWidth(meeting.duration);
            const isActive = meeting.status === 'inProgress';
            const isCompleted = ['ready', 'processing', 'failed'].includes(meeting.status);
            const progress = isActive ? getMeetingProgress(meeting.startDate, meeting.duration) : 0;

            return (
              <motion.div
                key={meeting.id}
                className={`timeline-meeting ${isActive ? 'active' : ''} ${isCompleted ? 'completed' : ''}`}
                style={{
                  left: `${position}%`,
                  width: `${width}%`,
                }}
                initial={{ opacity: 0, scale: 0.8 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ duration: 0.3, delay: index * 0.05 }}
                whileHover={{ scale: 1.05, zIndex: 10 }}
              >
                {isActive && (
                  <div 
                    className="meeting-progress"
                    style={{ width: `${progress}%` }}
                  />
                )}
                
                <div className="meeting-content">
                  <div className="meeting-time">{formatMeetingTime(meeting.startDate)}</div>
                  <div className="meeting-title-short">{meeting.title}</div>
                  <div className="meeting-duration">{formatDuration(meeting.duration)}</div>
                </div>

                <div className="meeting-tooltip">
                  <div className="tooltip-header">
                    <span className="tooltip-time">{formatMeetingTime(meeting.startDate)}</span>
                    <span className="tooltip-duration">{formatDuration(meeting.duration)}</span>
                  </div>
                  <div className="tooltip-title">{meeting.title}</div>
                  <div className="tooltip-status">
                    Status: {meeting.status}
                  </div>
                </div>
              </motion.div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
