public with sharing class Log {

	private static final Boolean LOG_VIA_EVENTS = logViaEvents();
	private static final String ORG_NAMESPACE = [SELECT NamespacePrefix FROM Organization].NamespacePrefix;
	private static final String CLASSNAME = Log.class.getName();
	private static final Pattern STACK_LINE = Pattern.compile('^(?:Class\\.)?([^.]+)\\.?([^\\.\\:]+)?[\\.\\:]?([^\\.\\:]*): line (\\d+), column (\\d+)$');


	// PUBLIC

	public static void debug(String message) {
		debug(message, new List<Object>(), null);
	}


	public static void debug(String message, List<Object> values) {
		debug(message, values, null);
	}


	public static void debug(String message, Id contextId) {
		debug(message, new List<Object>(), contextId);
	}


	public static void debug(Id contextId) {
		debug('', new List<Object>(), contextId);
	}


	public static void debug(String message, List<Object> values, Id contextId) {
		emit(message, values, contextId, LoggingLevel.DEBUG);
	}


	public static void error(String message) {
		error(message, new List<Object>(), null);
	}


	public static void error(String message, List<Object> values) {
		error(message, values, null);
	}


	public static void error(String message, Id contextId) {
		error(message, new List<Object>(), contextId);
	}


	public static void error(Id contextId) {
		error('', new List<Object>(), contextId);
	}


	public static void error(String message, List<Object> values, Id contextId) {
		emit(message, values, contextId, LoggingLevel.ERROR);
	}


	// PRIVATE

	private static void emit(String message, List<Object> values, Id contextId, LoggingLevel level) {
		message = String.format(message, cast(values));

		if(LOG_VIA_EVENTS) {
			currentEvent = new Log__e();
			currentEvent.txt_User__c = UserInfo.getUserId();
			currentEvent.txl_Message__c = message;
			currentEvent.txt_Level__c = level.name();
			currentEvent.txt_Context__c = (contextId == null) ? timestamp() : ''+contextId;

			populateLocation(currentEvent);

			EventBus.publish(currentEvent);
		}
		else {
			System.debug(level, message);
		}
	}


	private static List<String> cast(List<Object> values) {
		List<String> result = new List<String>();

		for(Object value : values) {
			result.add('' + value);
		}

		return result;
	}


	public static String timestamp() {
		return System.now().formatGmt('HH:mm:ss.SSS');
	}


	private static void populateLocation(Log__e logEvent) {
		List<String> stacktrace = new DmlException().getStackTraceString().split('\n');

		for(String line : stacktrace) {
			Matcher matcher = STACK_LINE.matcher(line);

			if(matcher.find() && !line.startsWith('Class.' + CLASSNAME + '.')) {
				Boolean hasNamespace = String.isNotBlank(matcher.group(3));

				if(hasNamespace) {
					logEvent.txt_Class__c = (matcher.group(1).equals(ORG_NAMESPACE)) ? matcher.group(2) : matcher.group(1) + '.' + matcher.group(2);
                    logEvent.txt_Method__c = prettyMethod(matcher.group(3));
				}
				else {
					logEvent.txt_Class__c = matcher.group(1);
                    logEvent.txt_Method__c = prettyMethod(matcher.group(2));
				}

				logEvent.num_Line__c = Integer.valueOf(matcher.group(4));

				return;
			}
		}
	}


	private static String prettyMethod(String method) {
		return (method.contains('init')) ? 'ctor' : method;
	}


	private static Boolean logViaEvents() {
		Settings__c settings = Settings__c.getValues(UserInfo.getUserId());
		return (settings == null) ? false : (System.today() == settings.dat_LogViaEvents__c);
	}


	// Note: Required to allow testing
	@TestVisible
	private static Log__e currentEvent = null;
}