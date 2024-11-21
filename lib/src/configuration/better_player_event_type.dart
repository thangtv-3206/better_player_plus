///Supported event types
enum BetterPlayerEventType {
  initialized,
  play,
  pause,
  seekTo,
  openFullscreen,
  hideFullscreen,
  setVolume,
  progress,
  finished,
  exception,
  controlsVisible,
  controlsHiddenStart,
  controlsHiddenEnd,
  setSpeed,
  changedSubtitles,
  changedTrack,
  changedPlayerVisibility,
  changedResolution,
  pipStart,
  pipStop,
  setupDataSource,
  bufferingStart,
  bufferingUpdate,
  bufferingEnd,
  changedPlaylistItem,
  prepareToPip, // in android auto PIP, when user Press Home or open other activity
  enteringPip, // Fire when start PIP by tap button in UI and close app.
  exitingPip, // Fire when start PIP by tap button in UI and open app from PIP.
}
