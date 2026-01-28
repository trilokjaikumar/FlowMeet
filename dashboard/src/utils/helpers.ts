import { format, formatDistance, differenceInMinutes, isToday, isTomorrow, isPast, isFuture } from 'date-fns';

export const formatMeetingTime = (dateString: string): string => {
  const date = new Date(dateString);
  return format(date, 'h:mm a');
};

export const formatMeetingDate = (dateString: string): string => {
  const date = new Date(dateString);
  
  if (isToday(date)) return 'Today';
  if (isTomorrow(date)) return 'Tomorrow';
  
  return format(date, 'MMM d');
};

export const formatFullDateTime = (dateString: string): string => {
  const date = new Date(dateString);
  return format(date, 'MMM d, yyyy • h:mm a');
};

export const getTimeUntilMeeting = (dateString: string): string => {
  const date = new Date(dateString);
  const now = new Date();
  
  if (isPast(date)) return 'Started';
  
  const minutes = differenceInMinutes(date, now);
  
  if (minutes < 1) return 'Starting now';
  if (minutes < 60) return `${minutes}m`;
  if (minutes < 1440) return `${Math.floor(minutes / 60)}h ${minutes % 60}m`;
  
  return formatDistance(date, now, { addSuffix: true });
};

export const formatDuration = (seconds: number): string => {
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  
  if (hours > 0) {
    return `${hours}h ${minutes}m`;
  }
  return `${minutes}m`;
};

export const getMeetingProgress = (startDate: string, duration: number): number => {
  const start = new Date(startDate).getTime();
  const now = Date.now();
  const elapsed = now - start;
  const durationMs = duration * 1000;
  
  return Math.min(100, Math.max(0, (elapsed / durationMs) * 100));
};

export const getStatusColor = (status: string): string => {
  const colors: Record<string, string> = {
    notStarted: 'var(--color-text-tertiary)',
    inProgress: 'var(--color-accent-primary)',
    processing: 'var(--color-accent-warning)',
    ready: 'var(--color-accent-success)',
    failed: 'var(--color-accent-error)'
  };
  
  return colors[status] || colors.notStarted;
};

export const getStatusLabel = (status: string): string => {
  const labels: Record<string, string> = {
    notStarted: 'Not Started',
    inProgress: 'In Progress',
    processing: 'Processing',
    ready: 'Ready',
    failed: 'Failed'
  };
  
  return labels[status] || status;
};

export const getModeLabel = (mode: string): string => {
  return mode === 'transparent' ? 'Transparent' : 'Incognito';
};

export const getSourceLabel = (source: string): string => {
  const labels: Record<string, string> = {
    appleCalendar: 'Apple Calendar',
    googleCalendar: 'Google Calendar',
    manual: 'Manual'
  };
  
  return labels[source] || source;
};

export const truncateText = (text: string, maxLength: number): string => {
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength) + '...';
};

export const groupMeetingsByDate = (meetings: any[]): Record<string, any[]> => {
  return meetings.reduce((groups, meeting) => {
    const date = formatMeetingDate(meeting.startDate);
    if (!groups[date]) {
      groups[date] = [];
    }
    groups[date].push(meeting);
    return groups;
  }, {} as Record<string, any[]>);
};

export const calculateStats = (meetings: any[]) => {
  const now = new Date();
  
  const upcomingMeetings = meetings.filter(m => 
    isFuture(new Date(m.startDate)) && m.status === 'notStarted'
  ).length;
  
  const completedToday = meetings.filter(m => {
    const meetingDate = new Date(m.startDate);
    return isToday(meetingDate) && (m.status === 'ready' || m.status === 'processing');
  }).length;
  
  const totalHoursRecorded = meetings
    .filter(m => m.status === 'ready' || m.status === 'processing')
    .reduce((sum, m) => sum + m.duration, 0) / 3600;
  
  const notesGenerated = meetings.filter(m => m.notes && m.status === 'ready').length;
  
  const completedMeetings = meetings.filter(m => 
    m.status === 'ready' || m.status === 'processing'
  );
  
  const averageMeetingDuration = completedMeetings.length > 0
    ? completedMeetings.reduce((sum, m) => sum + m.duration, 0) / completedMeetings.length / 60
    : 0;
  
  return {
    totalMeetings: meetings.length,
    upcomingMeetings,
    completedToday,
    totalHoursRecorded: Math.round(totalHoursRecorded * 10) / 10,
    averageMeetingDuration: Math.round(averageMeetingDuration),
    notesGenerated
  };
};
