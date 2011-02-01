/**
 * Hi-ReS! Logger
 * 
 * Released under MIT license:
 * http://www.opensource.org/licenses/mit-license.php 
 * 
 * How to use:
 * 
 * 	addChild( Logger.getMaster() );
 * 
 *	Logger.info("Info message");
 * 	Logger.debug("Debug message, result >", 1+2+3);
 * 	Logger.warning("This is just a warning!");
 * 	Logger.error("Ok, something crashed");
 * 	
 * 		or ...
 * 	
 * 	var customLogger:Logger = new Logger(1,"Custom Logger",false);
 * 	customLogger.info("Info Message");
 * 
 * version log:
 * 
 *  09.08.06	1.7	Theo		+ Fixed Flash 10 bug (<> converted to &lt; etc.) { arg still CDATA gets converted }
 *  							+ CSS display inline for debug nodes fixes spacing incoherence between text / XML output
 *  09.07.23	1.6	Theo		+ Added getXMLDump() returning the FULL log as XML (the visible log being just a fragment)
 *  				Mr.doob		  Removed getLog (depreciated) 
 *  							+ Removed the global/monitor properties (not used, can be solved by inheritance)
 *  							  Now using master, getMaster to access the "static" Logger
 *  							+ Removed stack (this is now stored in XML)
 *  				
 *  09.02.04	1.5	Mr.doob		+ Included stringPadNumber as a method (no more dependencies)
 *					Theo		+ CDATA for message *								+ XML used for logging
 *								+ CSS applied to XML show colors
 *								+ Replaced level names by colors in the display
 *								+ added getLog() method
 *								+ Added maxMessages field
 *								+ The class now extends TextField
 *								+ Added DEFAULT_NAME and name argument for the constructor
 *								+ Comments / Todos to be checked ...
 *	08.11.21	1.4	Theo		+ fix : the specified output level wasn't considered
 *								+ enh : stripping the comas from arrays in the log method to 
 *								  make the log clearer.
 *	08.11.12	1.3	Mr.doob		+ Instance mode
 *					Theo		+ Info level added
 *								+ Stack
 *	08.11.04	1.2	Mr.doob		+ Introduced debug, warning and error methods
 *								+ added visible getter/setter
 *	08.11.02	1.1	Mr.doob		+ Changed the LEVEL handling
 *								+ Slightly refactored
 * 	07.10.12	1.0	Mr.doob		+ First version 
 **/
package net.hires.debug
{
	import flash.text.StyleSheet;
	import flash.text.TextField;

	public class Logger extends TextField
	{

		private static const DEFAULT_NAME : String = "Hi-ReS! Logger";
		private static const _LEVEL_NAMES : Array = ['info', 'debug', 'warning', 'error'];
		private static const _LEVEL_COLOURS : Array = ['#ffffff', '#99E1FF', '#00CC33', '#FF3300', '#FF0000'];
		public static const LEVEL_INFO : int = 0;
		public static const LEVEL_DEBUG : int = 1;
		public static const LEVEL_WARNING : int = 2;
		public static const LEVEL_ERROR : int = 3;
		public static const LEVEL_SILENT : int = 4;

		public var level : int;

		private static var master : Logger;



		private var maxMessages : int;
		private var xmlLog : XML;
		private var xmlFullLog : XML;

		/**
		 * @param level			int			The level below which the messages wouldn't be logged
		 * @param name			String		An id for the logger, if not specified the DEFAULT_NAME will be used
		 * @param isMaster		Boolean		Indicates whether the logger should be notified by messages
		 * 									coming from the public 'static' interface.
		 * @param maxMessages	int			Maximum number of messages to store simultaneously.
		 * 									Set to zero to keep ALL the messages.
		 */
		public function Logger( level : int = 0, name : String = DEFAULT_NAME, isMaster : Boolean = true, maxMessages : int = 100 )
		{
			this.name = name;
			this.level = level;
			this.maxMessages = maxMessages;

			if (isMaster)
			{
				master = this;
			}

			initDisplay();
			clear();
		}


		protected function initDisplay() : void
		{
			autoSize = "left";
			// TODO : 	- Check colors (maybe white/grey for info? to make it bit less rainbowy)
			// - Default system 'monospace' doesn't seem to work
			var style : StyleSheet = new StyleSheet();
			style.setStyle("log", {color:_LEVEL_COLOURS[0], fontSize:"10px", fontFamily:"Monaco, Courier, monospace"});
			style.setStyle("info", {color:_LEVEL_COLOURS[1], display:'inline'});
			style.setStyle("debug", {color:_LEVEL_COLOURS[2], display:'inline'});
			style.setStyle("warning", {color:_LEVEL_COLOURS[3], display:'inline', textWeight:"bold"});
			style.setStyle("error", {color:_LEVEL_COLOURS[4], display:'inline'});
			styleSheet = style;
		}


		// Statics
		// ---------------------------------------------------------------------


		/**
		 * Returns the main singleton logger
		 */
		public static function getMaster() : Logger
		{
			if (master == null)
				master = new Logger();

			return master;
		}


		public static function info( ...msg : * ) : void
		{
			getMaster().log(msg, LEVEL_INFO);
		}


		public static function debug( ...msg : * ) : void
		{
			getMaster().log(msg, LEVEL_DEBUG);
		}


		public static function warning( ...msg : * ) : void
		{
			getMaster().log(msg, LEVEL_WARNING);
		}


		public static function error( ...msg : * ) : void
		{
			getMaster().log(msg, LEVEL_ERROR);
		}


		public static function clear() : void
		{
			getMaster().clear();
		}


		// Instance methods
		// ---------------------------------------------------------------------


		public function info( ...msg : * ) : void
		{
			log(msg, LEVEL_INFO);
		}


		public function debug( ...msg : * ) : void
		{
			log(msg, LEVEL_DEBUG);
		}


		public function warning( ...msg : * ) : void
		{
			log(msg, LEVEL_WARNING);
		}


		public function error( ...msg : * ) : void
		{
			log(msg, LEVEL_ERROR);
		}


		protected function log( msg : *, level : int = 0 ) : void
		{
			if (msg is Array) msg = (msg as Array).join(" ");

			msg = getTimestamp(new Date()) + " :: " + msg;

			var node : XML = <{_LEVEL_NAMES[level]}>{(msg)}</{_LEVEL_NAMES[level]}>;

			xmlFullLog.prependChild(node);

			if (level < this.level) return;

			xmlLog.prependChild(node);

			if (xmlLog.children().length() > maxMessages && maxMessages > 0)
			{
				delete xmlLog.children()[maxMessages];
			}

			htmlText = xmlLog;
		}


		public function getXMLDump() : XML
		{
			return xmlFullLog;
		}


		public function clear() : void
		{
			xmlLog = new XML("<log />");
			xmlFullLog = new XML("<log />");
			xmlLog.info = getTimestamp(new Date()) + " :: " + name + " > " + _LEVEL_NAMES[level] + " mode.";
			xmlFullLog.info = xmlLog.info;
			htmlText = xmlLog;
		}


		// Utils
		// ---------------------------------------------------------------------


		private static function getTimestamp( d : Date ) : String
		{
			return "[" + stringPadNumber(d.hours, 2) + ":" + stringPadNumber(d.minutes, 2) + ":" + stringPadNumber(d.seconds, 2) + "::" + stringPadNumber(d.milliseconds, 3) + "]";
		}


		private static function stringPadNumber( num : Number, padding : Number ) : String
		{
			var stringNum : String = String(num);
			while (stringNum.length < padding) stringNum = "0" + stringNum;
			return stringNum;
		}
	}
}