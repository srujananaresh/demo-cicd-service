#!/bin/sh


# Specific service management variables
SERVICE_NAME=DockerSampleApp
JAVA_OPTIONS="-Ddebug=true -Xms1024m -Xmx3072m -XX:ParallelGCThreads=15 -Doracle.net.tns_admin=/opt/SP/apps/config"


# Common service management variables
JAVA_CMD=/opt/SP/apps/java/bin/java
PATH_TO_PROJ_ROOT=/opt/SP/apps/$SERVICE_NAME
PATH_TO_JAR=$PATH_TO_PROJ_ROOT/app.jar
PID_PATH_NAME=$PATH_TO_PROJ_ROOT/application.pid

OLDCWD=`/bin/pwd`

# Get the currently running processes that match the service signature
APP_PID=`/bin/ps -eo pid,cmd |/bin/grep "${JAVA_CMD}" |/bin/grep "${PATH_TO_JAR}" |/bin/grep -v grep |/bin/awk '{print $1}'`

# Service Management Functions
status_function() {
  # Returns TRUE (0) if service is running (regardless of the PID in the PID File
  # matching or not with the running one) FALSE (1) otherwise

  # Function can optionally be silent [Skip all printouts]
  local SILENT=1; if [ $# -gt 0 ]; then SILENT=$1; fi

  # Local return codes
  local RUNNING=0       # Function concluded that service is running     - True
  local NOT_RUNNING=1   # Function concluded that service is not running - False

  # Output the currently running service information [Raw data]
  [ ${SILENT} -ne 0 ] && /bin/ps -e |/bin/grep "${JAVA_CMD}" |/bin/grep "${PATH_TO_JAR}" |/bin/grep -v grep

  # Refresh variable
  APP_PID=`/bin/ps -eo pid,cmd |/bin/grep "${JAVA_CMD}" |/bin/grep "${PATH_TO_JAR}" |/bin/grep -v grep |/bin/awk '{print $1}'`
  APP_PID_C=$(echo ${APP_PID} |wc -l)
  local FILE_PID=""; [ -f ${PID_PATH_NAME} ] && FILE_PID=$(cat ${PID_PATH_NAME})

  # Analyse the current running process output
  if [ -z "${APP_PID}" ]; then
    [ ${SILENT} -ne 0 ] && echo "Service ${SERVICE_NAME} is not running";
    if [ -n "${FILE_PID}" ]; then
      # Not running but a pid is listed in the PID file
      [ ${SILENT} -ne 0 ] && echo "PID file leftover remaining.";

    fi
    return ${NOT_RUNNING};

  elif [ ${APP_PID_C} -ne 1 ]; then
    [ ${SILENT} -ne 0 ] && echo "Service ${SERVICE_NAME} is in a incoerent state. Too many processes (${APP_PID_C}) running.";
    return ${RUNNING};

  fi

  [ ${SILENT} -ne 0 ] && echo "Service ${SERVICE_NAME} is running with PID ${APP_PID}";
  if [ -z "${FILE_PID}" ]; then
    [ ${SILENT} -ne 0 ] && echo "PID file is empty. Restart service to correct";

  elif [ "${FILE_PID}" -ne "${APP_PID}" ]; then
    [ ${SILENT} -ne 0 ] && echo "PID file content (${FILE_PID}) does not match currently running service PID (${APP_PID}). Restarting service corrects this.";

  fi
  return ${RUNNING};

}

start_function() {
  # Returns TRUE (0) if service has been successfully started or
  # FALSE (1) if already running or if the start attempt was
  # unsucessful (subsequent status call returned FALSE)

  # Function can optionally be silent [Skip some printouts]
  local SILENT=1; if [ $# -gt 0 ]; then SILENT=$1; fi

  # Local return codes
  local NOT_STARTED=1   # Function did not start service - False

  # Initial status always silent
  status_function 0;
  if [ $? -eq 0 ]; then
    status_function;
    echo "Service ${SERVICE_NAME} was not started. Already running";
    return ${NOT_STARTED}
  fi

  # Start can be performed because not running at the moment
  [ ${SILENT} -ne 0 ] && echo "Starting ${SERVICE_NAME} ...";

  cd ${PATH_TO_PROJ_ROOT}
  nohup ${JAVA_CMD} ${JAVA_OPTIONS} -jar ${PATH_TO_JAR} &>> /dev/null &
  echo $ > ${PID_PATH_NAME}

  # return to the invocation path
  cd ${OLDCWD}

  # Output final service running status
  status_function;
  # Return if the service was found to be running
  return $?
}

stop_function() {
  # Returns TRUE (0) if service has been successfully stopped or
  # FALSE (1) if not running or if the stopped attempt was
  # unsucessful (subsequent status call returned FALSE)

  # Function can optionally be silent [Skip some printouts]
  local SILENT=0; if [ $# -gt 0 ]; then SILENT=$1; fi
  # Local return codes
  local STOPPED=0       # Function stopped service - True
  local NOT_STOPPED=1   # Function did not stop service - False

  # Initial status always silent
  status_function 0;
  if [ $? -eq 0 ]; then
    # Service is running. Stop can be performed.
    echo "Service ${SERVICE_NAME} running. Stopping...";

    # In the wild hypothesis that more than one process is running
    # kill all of them.
    for pid in ${APP_PID}; do
      echo ${pid}
      kill -9 ${pid};
      if [ $? -eq 0 ]; then
        echo "Process with PID ${pid} killed";
      else
          echo $
      fi

    done

    sleep 5

    # Update the service running status
    status_function ${SILENT};
    if [ $? -eq 0 ]; then
      # Service still running
      echo "Service ${SERVICE_NAME} is still running. Failed to stop";
      return ${NOT_STOPPED}

    else
      # No longer running
      if [ -f ${PID_PATH_NAME} ]; then
        # Remove any leftover PID file
        rm ${PID_PATH_NAME}
        echo "File ${PID_PATH_NAME} removed";

      fi
      return ${STOPPED};
    fi

  fi

  echo "Service ${SERVICE_NAME} was not stopped. Was not running";
  if [ -f ${PID_PATH_NAME} ]; then
    # Remove any leftover PID file
    rm ${PID_PATH_NAME}
    echo "Leftover File ${PID_PATH_NAME} removed";

  fi
  return ${NOT_STOPPED}
}

restart_function() {
  # Returns TRUE (0) if service has been successfully restarted or
  # FALSE (1) if the stopped attempt was unsucessful (subsequent
  # status call returned FALSE) or the start attempt returned FALSE

  # Local return codes
  local NOT_RESTARTED=1   # Function did not restart service - False

  stop_function 0;
  if [ $? -ne 0 ]; then
    status_function 0;
    if [ $? -eq 0 ]; then
      # Service was found to be still running. Cannot start it again
      echo "Service ${SERVICE_NAME} is still running (Shouldn't be). Manual action needed";
      return ${NOT_RESTARTED}
    fi
  fi

  # Service no longer running (was successfully stopped or was not running at all)
  echo "Restarting Service ${SERVICE_NAME}...";
  start_function 0;
  return $?;

}

usage_function() {
  echo "Usage $0 start|stop|restart|status";
  return 1
}

case $1 in
  start)   start_function   ;;
  status)  status_function  ;;
  stop)    stop_function    ;;
  restart) restart_function ;;
  *)       usage_function   ;;
esac
exit $?
