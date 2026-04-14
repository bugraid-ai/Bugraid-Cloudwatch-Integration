const {
  CloudWatchClient,
  DescribeAlarmsCommand,
  PutMetricAlarmCommand,
} = require("@aws-sdk/client-cloudwatch");
const https = require("https");

/**
 * Will add the BugRaid Topic to all
 * enabled CloudWatch Alarms
 */
module.exports.handler = async (event, context) => {
  console.log('Event received:', JSON.stringify(event, null, 2));
  
  // Placeholder for results from processing event
  let responseStatus = "SUCCESS";
  let responseReason = "Success";

  try {
    // Identifies a CloudFormation Invocation
    if (event.RequestType) {
      console.log(`Processing CloudFormation ${event.RequestType} request`);
      
      switch (event.RequestType) {
        case "Create":
        case "Update":
          console.log("Adding Topic to alarms...");
          await addTopicToAlarms();
          break;
        case "Delete":
          console.log("Removing Topic from alarms...");
          await removeTopicFromAlarms();
          break;
        default:
          console.log(`Unknown request type: ${event.RequestType}`);
          responseStatus = "FAILED";
          responseReason = `Unknown request type: ${event.RequestType}`;
      }
    } else if (event.source && event.source === "aws.events") {
      // Identifies an Event Rule Invocation
      console.log("Processing Event Rule invocation");
      await addTopicToAlarms();
    } else {
      console.log("Processing regular Lambda invocation");
      await addTopicToAlarms();
    }

  } catch (error) {
    console.error('Error in handler:', error);
    responseStatus = "FAILED";
    responseReason = error.message || "Unknown error occurred";
  }

  // Send cfResponse only if a cf request
  if (event.RequestType) {
    try {
      console.log(`Sending CloudFormation response: ${responseStatus}`);
      const response = await cfResponse(
        event,
        context,
        responseStatus,
        responseReason
      );
      console.log(`CloudFormation Response sent successfully: ${response}`);
    } catch (error) {
      console.error(`CloudFormation Response Error: ${error}`);
      // Even if cfResponse fails, we need to try one more time
      try {
        await cfResponse(event, context, "FAILED", `Response failed: ${error.message}`);
      } catch (retryError) {
        console.error(`Retry response also failed: ${retryError}`);
      }
    }
  } else {
    return { 
      statusCode: responseStatus === "SUCCESS" ? 200 : 500,
      body: JSON.stringify({ 
        status: responseStatus,
        message: responseReason 
      })
    };
  }
};

const CloudWatch = new CloudWatchClient();

/**
 * Adds the BugRaid Topic to all
 * enabled CloudWatch Alarms
 */
const addTopicToAlarms = async () => {
  try {
    // Get alarms
    let alarms = await getAlarms();
    console.log(`Found ${alarms.length} total alarms`);

    // Filter alarms
    alarms = alarms.filter(alarmFilter);
    console.log(`Filtered to ${alarms.length} alarms`);

    // Add BugRaid Topic to alarms
    alarms = addBugRaidTopic(alarms);

    if (alarms.length > 0) {
      const results = await updateAlarms(alarms);
      const succeeded = results.filter(r => r.success).length;
      const failed = results.filter(r => !r.success).length;
      console.log(`Update complete: ${succeeded} succeeded, ${failed} failed out of ${alarms.length} alarms`);
      if (failed > 0) {
        const failedNames = results.filter(r => !r.success).map(r => r.alarmName).join(', ');
        console.error(`Failed alarms: ${failedNames}`);
      }
    } else {
      console.log("No alarms to update");
    }
  } catch (error) {
    console.error('Error in addTopicToAlarms:', error);
    throw error;
  }
};

/**
 * Removes the BugRaid Topic from
 * all the CloudWatch Alarms if it exists
 */
const removeTopicFromAlarms = async () => {
  try {
    // Get alarms
    let alarms = await getAlarms();
    console.log(`Found ${alarms.length} total alarms`);

    // Removing BugRaid Topic from Alarms
    alarms = removeBugRaidTopic(alarms);

    if (alarms.length > 0) {
      const results = await updateAlarms(alarms);
      const succeeded = results.filter(r => r.success).length;
      const failed = results.filter(r => !r.success).length;
      console.log(`Removal complete: ${succeeded} succeeded, ${failed} failed out of ${alarms.length} alarms`);
      if (failed > 0) {
        const failedNames = results.filter(r => !r.success).map(r => r.alarmName).join(', ');
        console.error(`Failed alarms: ${failedNames}`);
      }
    } else {
      console.log("No alarms to update");
    }
  } catch (error) {
    console.error('Error in removeTopicFromAlarms:', error);
    throw error;
  }
};

/**
 * Adds the BugRaid Topic to the alarm actions
 * @param {Array} alarms CloudWatch Alarms
 * @returns {Array} CloudWatch Alarms with BugRaid Topic added
 */
const addBugRaidTopic = (alarms) => {
  const topicArn = process.env.TOPICARN;
  if (!topicArn) {
    throw new Error("TOPICARN environment variable is not set");
  }

  return alarms.reduce((modified, alarm) => {
    const hasAlarmTopic = alarm.AlarmActions && alarm.AlarmActions.includes(topicArn);
    const hasOkTopic = alarm.OKActions && alarm.OKActions.includes(topicArn);
    const hasInsufficientTopic = alarm.InsufficientDataActions && alarm.InsufficientDataActions.includes(topicArn);

    if (!hasAlarmTopic || !hasOkTopic || !hasInsufficientTopic) {
      console.log(`Adding BugRaid Topic to alarm: ${alarm.AlarmName}`);
      modified.push({
        ...alarm,
        AlarmActions: hasAlarmTopic ? alarm.AlarmActions : [...(alarm.AlarmActions || []), topicArn],
        OKActions: hasOkTopic ? alarm.OKActions : [...(alarm.OKActions || []), topicArn],
        InsufficientDataActions: hasInsufficientTopic ? alarm.InsufficientDataActions : [...(alarm.InsufficientDataActions || []), topicArn],
      });
    } else {
      console.log(`Alarm ${alarm.AlarmName} already has all BugRaid Topics, skipping`);
    }
    return modified;
  }, []);
};

/**
 * Removes the BugRaid Topic from the alarm actions
 * @param {Array} alarms CloudWatch Alarms
 * @returns {Array} CloudWatch Alarms with BugRaid Topic removed
 */
const removeBugRaidTopic = (alarms) => {
  const topicArn = process.env.TOPICARN;
  if (!topicArn) {
    throw new Error("TOPICARN environment variable is not set");
  }

  return alarms.reduce((modified, alarm) => {
    const hasAlarmTopic = alarm.AlarmActions && alarm.AlarmActions.includes(topicArn);
    const hasOkTopic = alarm.OKActions && alarm.OKActions.includes(topicArn);
    const hasInsufficientTopic = alarm.InsufficientDataActions && alarm.InsufficientDataActions.includes(topicArn);

    if (hasAlarmTopic || hasOkTopic || hasInsufficientTopic) {
      console.log(`Removing BugRaid Topic from alarm: ${alarm.AlarmName}`);
      modified.push({
        ...alarm,
        AlarmActions: alarm.AlarmActions ? alarm.AlarmActions.filter(action => action !== topicArn) : [],
        OKActions: alarm.OKActions ? alarm.OKActions.filter(action => action !== topicArn) : [],
        InsufficientDataActions: alarm.InsufficientDataActions ? alarm.InsufficientDataActions.filter(action => action !== topicArn) : [],
      });
    } else {
      console.log(`Alarm ${alarm.AlarmName} doesn't have BugRaid Topic, skipping`);
    }
    return modified;
  }, []);
};

/**
 * Sanitizes a DescribeAlarms response object for use with PutMetricAlarmCommand.
 * Removes read-only fields and resolves conflicts between Dimensions and Metrics.
 * @param {Object} alarm Raw alarm from DescribeAlarms
 * @returns {Object} Alarm safe for PutMetricAlarm
 */
const sanitizeAlarmForPut = (alarm) => {
  const sanitized = { ...alarm };

  // Remove read-only fields returned by DescribeAlarms
  delete sanitized.AlarmArn;
  delete sanitized.AlarmConfigurationUpdatedTimestamp;
  delete sanitized.StateValue;
  delete sanitized.StateReason;
  delete sanitized.StateReasonData;
  delete sanitized.StateUpdatedTimestamp;
  delete sanitized.StateTransitionedTimestamp;

  // Metric math alarms use Metrics array — Dimensions/MetricName/Namespace/Statistic/Period
  // must NOT be set alongside Metrics
  if (sanitized.Metrics && sanitized.Metrics.length > 0) {
    delete sanitized.Dimensions;
    delete sanitized.MetricName;
    delete sanitized.Namespace;
    delete sanitized.Statistic;
    delete sanitized.ExtendedStatistic;
    delete sanitized.Period;
    delete sanitized.Unit;
  }

  return sanitized;
};

/**
 * Updates CloudWatch Alarms
 * @param {Array} alarms CloudWatch Alarms to update
 * @returns {Array} Results from updating alarms
 */
const updateAlarms = async (alarms) => {
  const results = [];
  // CloudWatch PutMetricAlarm rate limit is ~3 TPS; 350ms between calls is safe
  const delayMs = 350;

  for (let i = 0; i < alarms.length; i++) {
    const alarm = alarms[i];
    try {
      console.log(`Updating alarm: ${alarm.AlarmName}`);
      const sanitized = sanitizeAlarmForPut(alarm);
      await CloudWatch.send(new PutMetricAlarmCommand(sanitized));
      results.push({ success: true, alarmName: alarm.AlarmName });
      if (i < alarms.length - 1) {
        await new Promise((resolve) => setTimeout(resolve, delayMs));
      }
    } catch (error) {
      console.error(`Error updating alarm ${alarm.AlarmName}:`, error);
      results.push({ success: false, alarmName: alarm.AlarmName, error: error.message });
    }
  }
  return results;
};

/**
 * Removes any autoscaling alarms
 * @param {Object} alarm CloudWatch Alarm
 * @returns {Object} CloudWatch Alarm that passed filtering
 */
const alarmFilter = (alarm) => {
  if (alarm.ActionsEnabled) {
    if (
      alarm.AlarmDescription &&
      !alarm.AlarmDescription.startsWith("DO NOT EDIT OR DELETE.")
    ) {
      return alarm;
    }

    if (!alarm.AlarmDescription) {
      return alarm;
    }
  }
};

/**
 * Gets all CloudWatch Alarms
 * @returns {Array} CloudWatch Alarms
 */
const getAlarms = async () => {
  let opts = {},
    data = {},
    alarms = [];

  do {
    data = await CloudWatch.send(new DescribeAlarmsCommand(opts));
    alarms = alarms.concat(data.MetricAlarms || []);
    opts.NextToken = data.NextToken;
  } while (data.NextToken);

  return alarms;
};

/**
 * Wrapping the cfn-response code within a promise
 * @param {Object} event Lambda event
 * @param {Object} context Lambda object
 * @param {String} responseStatus status of response
 * @param {String} reason Failure reason to the CloudFormation response
 * @returns status code of https.request response
 */
const cfResponse = (event, context, responseStatus, reason) => {
  return new Promise((resolve, reject) => {
    const responseBody = JSON.stringify({
      Status: responseStatus,
      Reason: reason || "No reason provided",
      PhysicalResourceId: context.logStreamName,
      StackId: event.StackId,
      RequestId: event.RequestId,
      LogicalResourceId: event.LogicalResourceId,
      NoEcho: false,
    });

    console.log('Sending CloudFormation response:', responseBody);

    const parsedUrl = new URL(event.ResponseURL);

    const options = {
      hostname: parsedUrl.hostname,
      port: 443,
      path: parsedUrl.pathname + parsedUrl.search,
      method: "PUT",
      headers: {
        "content-type": "application/json",
        "content-length": responseBody.length,
      },
    };

    // Make request
    const request = https.request(options, (response) => {
      console.log("CloudFormation response status code: " + response.statusCode);
      resolve(response.statusCode);
    });

    // Catch and throw error from request
    request.on("error", (error) => {
      console.error("HTTPS Request Failed:", error);
      reject(`HTTPS Request Failed: ${error}`);
    });

    // Write response
    request.write(responseBody);
    request.end();
  });
};
