interface FlowmeetMessageHandler {
  postMessage(message: { type: string; payload?: Record<string, unknown> }): void;
}

interface Window {
  webkit?: {
    messageHandlers?: {
      flowmeet?: FlowmeetMessageHandler;
    };
  };
  flowmeetReceiveSettings?: (settings: Record<string, unknown>) => void;
  flowmeetReceiveMeetings?: (meetings: unknown[]) => void;
  flowmeetReceiveRecordingStatus?: (status: { isRecording: boolean; level: number }) => void;
  flowmeetReceiveCalendarStatus?: (status: { appleCalendarGranted: boolean; googleCalendarConnected: boolean }) => void;
}
