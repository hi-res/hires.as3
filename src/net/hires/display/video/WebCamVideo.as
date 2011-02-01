package net.hires.display.video
{
	import flash.events.ActivityEvent;
	import flash.events.StatusEvent;
	import flash.events.TimerEvent;
	import flash.media.Camera;
	import flash.media.Video;
	import flash.system.Security;
	import flash.system.SecurityPanel;
	import flash.utils.Timer;

	/**
	 * @version		1.0
	 * @author 		Theo
	 * 		     	+ big thanks to Aaron Meyers for Google Adapter Hack
	 * 
	 * @example
	 * 
	 *		var webcamVideo:WebCamVideo = new WebCamVideo( 640, 480 );
	 *		addChild( webcamVideo );
	 *		webcamVideo.addEventListener(StatusEvent.STATUS, onStatusEvent );
	 *		webcamVideo.start();
	 * 		
	 * 		function onStatusEvent( event : StatusEvent ) : void
	 * 		{
	 *			trace(this, "onWebCamStatus", event.level, event.code);
	 * 		}
	 * 	
	 */
	public class WebCamVideo extends Video
	{

		// StatusEvent status codes

		public static const STATUS_SUCCESS : String = "Camera.Success";
		public static const STATUS_ALLOWED : String = "Camera.Unmuted";
		public static const STATUS_DISALLOWED : String = "Camera.Muted";
		public static const STATUS_NO_ACTIVITY : String = "Camera.NoActivity";
		public static const STATUS_NO_CAMERA : String = "Camera.NoCamera";

		// Settings

		public var forceGAHack : Boolean = true;
		public var autoSelectUSBCamera : Boolean = false;
		public var autoSelectiSight : Boolean = false;
		public var activityTimeout : uint = 3000;

		// Private

		private var activityTimer : Timer;


		/**
		 * @param width		Width of the video
		 * @param height	Height of the video
		 */
		public function WebCamVideo( width : int, height : int )
		{
			super(width, height);
		}


		/**
		 * Activates the webcam 
		 */
		public function start() : void
		{
			selectCamera();

			if (_camera == null)
			{
				dispatchEvent(new StatusEvent(StatusEvent.STATUS, false, false, STATUS_NO_CAMERA, "error"));
				return;
			}

			if (_camera.muted)
			{
				_camera.addEventListener(StatusEvent.STATUS, onCameraStatus);
			}
			else
			{
				checkCameraFeedback();
			}

			// Attaching camera to the video object, this will pop-up the Adobe Privacy Setting dialog if
			// the camera not yet allowed

			attachCamera(_camera);
		}


		/**
		 * Stops the webcam and clears the video.
		 */
		public function stop() : void
		{
			if (_camera == null) return;

			disposeActivityTimer();

			_camera.removeEventListener(StatusEvent.STATUS, onCameraStatus);
			_camera = null;

			attachCamera(null);
			clear();
		}


		private function selectCamera() : void
		{
			var autoselectCamIndex : Number = -1,
			camIndex : Number,
			camName : String;

			for (camIndex = 0; camIndex < Camera.names.length; camIndex++)
			{
				camName = String(Camera.names[camIndex]);

				if (autoSelectiSight && camName.indexOf("iSight") > -1)
				{
					autoselectCamIndex = camIndex;
					break;
				}

				if (autoSelectUSBCamera && camName.indexOf("USB Video Class Video") > -1)
				{
					autoselectCamIndex = camIndex;
					break;
				}
			}

			// Aaron Meyers Google Adapters hack ^^

			if ( forceGAHack )
			{
				for (camIndex = 0; camIndex < Camera.names.length; camIndex++)
				{
					if ((Camera.names[camIndex] as String).indexOf('Google') == 0 )
					{
						(new Video(this.width, this.height)).attachCamera(Camera.getCamera(String(camIndex)));
					}
				}
			}

			if ( autoselectCamIndex > -1 )
			{
				// Autoselecting the camera seems to work very randomly specially if several webcams are installed.
				_camera = (autoselectCamIndex > -1) ? Camera.getCamera(String(autoselectCamIndex)) : Camera.getCamera();
			}
			else
			{
				// Selects the last camera the user last choosed
				_camera = Camera.getCamera();
			}
		}


		private function onCameraStatus( event : StatusEvent ) : void
		{
			switch (event.code)
			{
				case "Camera.Muted":

					dispatchEvent(new StatusEvent(StatusEvent.STATUS, false, false, STATUS_DISALLOWED, "warning"));
					break;

				case "Camera.Unmuted":

					dispatchEvent(new StatusEvent(StatusEvent.STATUS, false, false, STATUS_ALLOWED, "status"));
					checkCameraFeedback();
					break;
			}
		}


		// Activity
		// ---------------------------------------------------------------------


		private function checkCameraFeedback() : void
		{
			_camera.setMotionLevel(5, 500);
			_camera.addEventListener(ActivityEvent.ACTIVITY, onActivity);

			disposeActivityTimer();

			activityTimer = new Timer(activityTimeout, 1);
			activityTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onActivityTimeout);
			activityTimer.start();
		}


		private function onActivityTimeout( e : TimerEvent ) : void
		{
			disposeActivityTimer();

			_camera.removeEventListener(ActivityEvent.ACTIVITY, onActivity);

			dispatchEvent(new StatusEvent(StatusEvent.STATUS, false, false, STATUS_NO_ACTIVITY, "warning"));

			if (Camera.names.length > 1)
			{
				Security.showSettings(SecurityPanel.CAMERA);
			}
		}


		private function onActivity( event : ActivityEvent ) : void
		{
			disposeActivityTimer();

			_camera.removeEventListener(ActivityEvent.ACTIVITY, onActivity);

			dispatchEvent(new StatusEvent(StatusEvent.STATUS, false, false, STATUS_SUCCESS));
		}


		private function disposeActivityTimer() : void
		{
			if (activityTimer == null) return;

			activityTimer.stop();
			activityTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onActivityTimeout);
			activityTimer = null;
		}


		// Getters
		// ---------------------------------------------------------------------


		private var _camera : Camera;

		public function get camera() : Camera
		{
			return _camera;
		}
	}
}
