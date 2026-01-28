import { Meeting } from '../types';

export const mockMeetings: Meeting[] = [
  {
    id: '1',
    title: 'Product Strategy Review',
    startDate: new Date(Date.now() + 3600000).toISOString(), // 1 hour from now
    duration: 3600,
    zoomUrl: 'https://zoom.us/j/1234567890',
    source: 'appleCalendar',
    mode: 'transparent',
    status: 'notStarted',
    calendarEventId: 'cal_1'
  },
  {
    id: '2',
    title: 'Engineering Standup',
    startDate: new Date(Date.now() + 7200000).toISOString(), // 2 hours from now
    duration: 1800,
    zoomUrl: 'https://zoom.us/j/0987654321',
    source: 'appleCalendar',
    mode: 'transparent',
    status: 'notStarted',
    calendarEventId: 'cal_2'
  },
  {
    id: '3',
    title: 'Client Presentation',
    startDate: new Date(Date.now() + 86400000).toISOString(), // Tomorrow
    duration: 5400,
    zoomUrl: 'https://zoom.us/j/1122334455',
    source: 'manual',
    mode: 'incognito',
    status: 'notStarted'
  },
  {
    id: '4',
    title: 'Q4 Planning Session',
    startDate: new Date(Date.now() - 3600000).toISOString(), // 1 hour ago
    duration: 7200,
    zoomUrl: 'https://zoom.us/j/5544332211',
    source: 'appleCalendar',
    mode: 'transparent',
    status: 'ready',
    calendarEventId: 'cal_4',
    notes: {
      summary: 'Discussed Q4 objectives, revenue targets, and product roadmap. Team aligned on key priorities and resource allocation.',
      keyTakeaways: [
        'Target 30% revenue growth in Q4',
        'Launch two major product features by November',
        'Expand engineering team by 5 people',
        'Focus on enterprise customer acquisition'
      ],
      actionItems: [
        {
          id: 'action_1',
          task: 'Prepare detailed roadmap presentation',
          assignee: 'Sarah',
          completed: false
        },
        {
          id: 'action_2',
          task: 'Begin hiring process for engineers',
          assignee: 'Mike',
          completed: false
        },
        {
          id: 'action_3',
          task: 'Create Q4 budget proposal',
          assignee: 'Lisa',
          completed: true
        }
      ],
      fullTranscript: 'Full meeting transcript would appear here...'
    }
  },
  {
    id: '5',
    title: 'Design Review',
    startDate: new Date(Date.now() - 7200000).toISOString(), // 2 hours ago
    duration: 2700,
    zoomUrl: 'https://zoom.us/j/9988776655',
    source: 'appleCalendar',
    mode: 'transparent',
    status: 'processing',
    calendarEventId: 'cal_5'
  },
  {
    id: '6',
    title: 'Weekly Team Sync',
    startDate: new Date(Date.now() - 86400000).toISOString(), // Yesterday
    duration: 1800,
    zoomUrl: 'https://zoom.us/j/6677889900',
    source: 'appleCalendar',
    mode: 'transparent',
    status: 'ready',
    calendarEventId: 'cal_6',
    notes: {
      summary: 'Weekly team sync covering project updates, blockers, and upcoming priorities.',
      keyTakeaways: [
        'Project Alpha on track for delivery',
        'Need more design resources for Project Beta',
        'Customer feedback has been overwhelmingly positive'
      ],
      actionItems: [
        {
          id: 'action_4',
          task: 'Review customer feedback analysis',
          assignee: 'John',
          completed: true
        },
        {
          id: 'action_5',
          task: 'Schedule design resource meeting',
          assignee: 'Emma',
          completed: false
        }
      ]
    }
  },
  {
    id: '7',
    title: 'Marketing Campaign Review',
    startDate: new Date(Date.now() + 172800000).toISOString(), // 2 days from now
    duration: 3600,
    zoomUrl: 'https://zoom.us/j/4455667788',
    source: 'googleCalendar',
    mode: 'transparent',
    status: 'notStarted',
    calendarEventId: 'cal_7'
  },
  {
    id: '8',
    title: 'One-on-One with Manager',
    startDate: new Date(Date.now() + 259200000).toISOString(), // 3 days from now
    duration: 1800,
    zoomUrl: 'https://zoom.us/j/1231231234',
    source: 'appleCalendar',
    mode: 'incognito',
    status: 'notStarted',
    calendarEventId: 'cal_8'
  }
];

export const mockSettings = {
  joinOffsetMinutes: 2,
  defaultMode: 'transparent' as const,
  incognitoEnabled: true,
  appleCalendarEnabled: true,
  googleCalendarEnabled: false,
  calendarSyncDays: 7,
  audioSource: 'microphone' as const,
  transcriptionModel: 'whisper-1',
  notesModel: 'gpt-4-turbo-preview'
};
