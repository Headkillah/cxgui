﻿namespace CXGUI.VideoEncoding

import System
import System.Threading
import CXGUI
import System.Windows.Forms

class x264Handler(VideoEncoderHandler):
"""Description of x264Handler"""
	_startTime as date
	
	_errOccured as bool
	
	_config as x264Config
	
	public def constructor(avisynthScriptFile as string, destinationFile as string):
		self._errOccured = false
		
		super(avisynthScriptFile, destinationFile)
		_encoderPath = "x264.exe"
		_encodingProcess.StartInfo.FileName = _encoderPath

	public def Start():
		self.Start(1)
		if self._config.TotalPass > 1:
			self.Start(2)
		if self._config.TotalPass == 3:
			self.Start(3)
		self.processingDone = true

	private def Start(currentPass as int):
		
		_config.CurrentPass = currentPass
#		MessageBox.Show(_config.GetArgument())
		if _config.CurrentPass < _config.TotalPass:
			output = "NUL"
		else:
			output = "\"${_destinationFile}\""
		_encodingProcess.StartInfo.Arguments = "${_config.GetArgument()} --output ${output} \"${_avisynthScriptFile}\""
		_encodingProcess.StartInfo.UseShellExecute = false
		_encodingProcess.StartInfo.RedirectStandardError = true
		_encodingProcess.StartInfo.CreateNoWindow = true
		readThread = Thread(ThreadStart(ReadStdErr))
		_startTime = date.Now
		_encodingProcess.Start()
		readThread.Start()
		_encodingProcess.WaitForExit()
		if _errOccured:
			if _config.UsingCustomCmd:
				raise BadEncoderCmdException("Encoding failed due to bad custom command line.")
			else:
				raise InvalidVideoAvisynthScriptException(_avisynthScriptFile)
		else:
			if _progress >= 99:
				_progress = 100
			_timeLeft = timespan(0)
			readThread.Abort()

	private def ReadStdErr():
		sr = _encodingProcess.StandardError
		_line = ""
		while true:
			_line = sr.ReadLine()
			_line = "" if _line == null		
			
#			if _line.Length != 0 and not _line.StartsWith("["):
#				File.AppendAllText("d:\\x264log.txt", _line+'\r\n')	
				
			if _line.StartsWith("["):
				UpdateProgress(_line)
			elif _line.Contains("error"):
				_errOccured = true
			
	private def UpdateProgress(line as string):
		info = line.Split(char(','))
		frame = info[0]
		_currentFrame = int.Parse(frame[frame.IndexOf("]")+1:frame.IndexOf("/")])
		_progress = double.Parse(frame[frame.IndexOf("[")+1:frame.IndexOf("%")])
		bitRate = info[2]
		_currentPosition = cast(double, _currentFrame) / _scriptFrameRate
		double.TryParse(bitRate[:bitRate.IndexOf("k")], _avgBitRate)
		_currentFileSize = _avgBitRate * _currentPosition / 8
		_estimatedFileSize = _avgBitRate * _totalLength / 8
		pFrameRate = info[1]
		_ProcessingFrameRate = double.Parse(pFrameRate[:pFrameRate.IndexOf("f")])
		timeLeft = info[3]
		_timeLeft = timespan.Parse(timeLeft[timeLeft.IndexOf('a')+1:])
		_timeUsed = date.Now - _startTime
		_timeUsed = timespan.FromSeconds(cast(int, _timeUsed.TotalSeconds))
	

	def Stop():
		try:
			_encodingProcess.Kill()
			_encodingProcess.WaitForExit()
		except:
			pass
			
			
	//Properties
	Config as x264Config:
		get:
			return self._config
		set:
			self._config = value
	
public def vetest():
	t = x264Handler("""C:\Users\Public\Videos\Sample Videos\Wildlife.avs""", """c:\.mp4""")
	t.Start()

