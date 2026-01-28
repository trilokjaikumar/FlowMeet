export type MeetingStatus = 'notStarted' | 'inProgress' | 'processing' | 'ready' | 'failed';

export type MeetingMode = 'transparent' | 'incognito';

export type MeetingSource = 'appleCalendar' | 'googleCalendar' | 'manual';

export interface ActionItem {
  id: string;
  task: string;
  assignee?: string;
  completed: boolean;
}

export interface MeetingNotes {
  summary: string;
  keyTakeaways: string[];
  actionItems: ActionItem[];
  fullTranscript?: string;
}

export interface Meeting {
  id: string;
  title: string;
  startDate: string;
  duration: number;
  zoomUrl?: string;
  zoomId?: string;
  zoomPasscode?: string;
  source: MeetingSource;
  mode: MeetingMode;
  status: MeetingStatus;
  notes?: MeetingNotes;
  calendarEventId?: string;
}

export interface DashboardStats {
  totalMeetings: number;
  upcomingMeetings: number;
  completedToday: number;
  totalHoursRecorded: number;
  averageMeetingDuration: number;
  notesGenerated: number;
}

export interface TimelineEvent {
  id: string;
  meetingId: string;
  title: string;
  startTime: string;
  duration: number;
  status: MeetingStatus;
  type: 'meeting' | 'break';
}

export interface AudioVisualization {
  level: number;
  frequency: number[];
  isRecording: boolean;
}

export interface AppSettings {
  joinOffsetMinutes: number;
  defaultMode: MeetingMode;
  incognitoEnabled: boolean;
  appleCalendarEnabled: boolean;
  googleCalendarEnabled: boolean;
  calendarSyncDays: number;
  audioSource: 'microphone' | 'systemAudio';
  transcriptionModel: string;
  notesModel: string;
}
