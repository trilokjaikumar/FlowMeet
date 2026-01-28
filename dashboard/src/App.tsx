import { useState, useEffect } from 'react';
import { Dashboard } from './pages/Dashboard';
import { Meeting } from './types';
import { mockMeetings } from './data/mockData';
import './styles/globals.css';

function App() {
  const [meetings, setMeetings] = useState<Meeting[]>(mockMeetings);
  const [isRecording, setIsRecording] = useState(false);
  const [audioLevel, setAudioLevel] = useState(0);

  // Simulate audio level changes when recording
  useEffect(() => {
    if (!isRecording) {
      setAudioLevel(0);
      return;
    }

    const interval = setInterval(() => {
      // Simulate fluctuating audio levels
      const newLevel = Math.random() * 60 + 30; // Between 30-90
      setAudioLevel(newLevel);
    }, 200);

    return () => clearInterval(interval);
  }, [isRecording]);

  // Check for active meetings and update recording status
  useEffect(() => {
    const checkActiveMeetings = () => {
      const now = new Date();
      const activeMeeting = meetings.find(m => {
        const start = new Date(m.startDate);
        const end = new Date(start.getTime() + m.duration * 1000);
        return m.status === 'inProgress' || (now >= start && now <= end && m.status === 'notStarted');
      });

      setIsRecording(!!activeMeeting);
    };

    checkActiveMeetings();
    const interval = setInterval(checkActiveMeetings, 10000); // Check every 10 seconds

    return () => clearInterval(interval);
  }, [meetings]);

  const handleJoinMeeting = (meeting: Meeting) => {
    console.log('Joining meeting:', meeting.title);
    
    // Update meeting status to in progress
    setMeetings(prev =>
      prev.map(m =>
        m.id === meeting.id
          ? { ...m, status: 'inProgress' as const }
          : m
      )
    );

    // In a real app, this would trigger the Swift app to join the meeting
    if (window.webkit?.messageHandlers?.joinMeeting) {
      window.webkit.messageHandlers.joinMeeting.postMessage({
        meetingId: meeting.id,
        zoomUrl: meeting.zoomUrl
      });
    }
  };

  const handleMeetingClick = (meeting: Meeting) => {
    console.log('Meeting clicked:', meeting.title);
    
    // In a real app, this would open the meeting detail view
    if (window.webkit?.messageHandlers?.showMeetingDetail) {
      window.webkit.messageHandlers.showMeetingDetail.postMessage({
        meetingId: meeting.id
      });
    }
  };

  // Listen for messages from Swift
  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      const { type, data } = event.data;

      switch (type) {
        case 'updateMeetings':
          setMeetings(data.meetings);
          break;
        case 'updateMeetingStatus':
          setMeetings(prev =>
            prev.map(m =>
              m.id === data.meetingId
                ? { ...m, status: data.status }
                : m
            )
          );
          break;
        case 'updateAudioLevel':
          setAudioLevel(data.level);
          break;
        default:
          break;
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, []);

  return (
    <Dashboard
      meetings={meetings}
      onJoinMeeting={handleJoinMeeting}
      onMeetingClick={handleMeetingClick}
      isRecording={isRecording}
      audioLevel={audioLevel}
    />
  );
}

export default App;
