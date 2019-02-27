#!/bin/bash

cd /Release-v${CS_VERSION}

replace_toml_value () {
    val=$(echo $3 | sed 's/\//\\\//g')
    sed -i -e '/^\['"$1"'\]$/ , /^\[.*\]$/ s/^\('"$2"' = \).*$/\1'"$val"'/' $4
}

if [ -z "$CLUSTER_NAME" ]; then
    CLUSTER_NAME="woogeen-cluster"
fi

if [ -z "$DB_URL" ]; then
    DB_URL="mongo/nuvedb"
fi

if [ -z "$RABBIT_HOST" ]; then
    RABBIT_HOST="rabbit"
fi

if [ -z "$NUVE_HOST" ]; then
    NUVE_HOST="nuve"
fi

if [ -z "$PORTAL_HOST" ]; then
    PORTAL_HOST="portal"
fi

if [ -z "$PORTAL_PORT" ]; then
    PORTAL_PORT="8080"
fi

if [ -z "$PORTAL_SSL" ]; then
    PORTAL_SSL="false"
fi

if [ -z "$NODE_CMD" ]; then
    NODE_CMD="node"
fi

case $INSTANCE_TYPE in
    "nuve")
        CONFIG_FILE="./${INSTANCE_TYPE}/${INSTANCE_TYPE}.toml"
        replace_toml_value cluster name '"'$CLUSTER_NAME'"' $CONFIG_FILE
        replace_toml_value mongo dataBaseURL '"'$DB_URL'"' $CONFIG_FILE
        replace_toml_value rabbit host '"'$RABBIT_HOST'"' $CONFIG_FILE
        if [ -n "$INIT_NUVE" ]; then
            echo "Initializing nuve instance"
            ./nuve/init.sh --dburl=$DB_URL
        fi
        if [ -n "$PORTAL_PUBLIC_SSL" ]; then
            TOKENS_RESOURCE_FILE="./nuve/resource/tokensResource.js"
            sed -i -e 's/e.ssl/true/g' $TOKENS_RESOURCE_FILE
        fi
        ;;
    "cluster_manager")  
        CONFIG_FILE="./${INSTANCE_TYPE}/${INSTANCE_TYPE}.toml"
        replace_toml_value manager name '"'$CLUSTER_NAME'"' $CONFIG_FILE
        replace_toml_value rabbit host '"'$RABBIT_HOST'"' $CONFIG_FILE
        ;;
    "portal")
        CONFIG_FILE="./${INSTANCE_TYPE}/${INSTANCE_TYPE}.toml"
        replace_toml_value portal hostname '"'$PORTAL_HOST'"' $CONFIG_FILE
        replace_toml_value portal port $PORTAL_PORT $CONFIG_FILE
        replace_toml_value portal ssl $PORTAL_SSL $CONFIG_FILE
        replace_toml_value cluster name '"'$CLUSTER_NAME'"' $CONFIG_FILE
        replace_toml_value mongo dataBaseURL '"'$DB_URL'"' $CONFIG_FILE
        replace_toml_value rabbit host '"'$RABBIT_HOST'"' $CONFIG_FILE
        ;;
    "audio" | "video" | "conference" | "webrtc" | "streaming" | "recording" | "sip")
        CONFIG_FILE="./${INSTANCE_TYPE}_agent/agent.toml"
        replace_toml_value cluster name '"'$CLUSTER_NAME'"' $CONFIG_FILE
        replace_toml_value rabbit host '"'$RABBIT_HOST'"' $CONFIG_FILE
        case $INSTANCE_TYPE in
            "conference")
                replace_toml_value mongo dataBaseURL '"'$DB_URL'"' $CONFIG_FILE
                ;;
            "webrtc")
                replace_toml_value webrtc maxport $MAXPORT $CONFIG_FILE
                replace_toml_value webrtc minport $MINPORT $CONFIG_FILE
                ;;
        esac
        ;;
    "management_console")
        CONFIG_FILE="./${INSTANCE_TYPE}/${INSTANCE_TYPE}.toml"
        replace_toml_value nuve host '"'http://$NUVE_HOST:3000'"' $CONFIG_FILE
        ;;
    "app")
        SERVICE_FILE="./extras/basic_example/samplertcservice.js"
        sed -i -e 's~_service_ID_~'"$SERVICE_ID"'~g' $SERVICE_FILE
        sed -i -e 's~_service_KEY_~'"$SERVICE_KEY"'~g' $SERVICE_FILE
        sed -i -e 's/localhost/'"$NUVE_HOST"'/g' $SERVICE_FILE
        if [ -n "$TURN_HOST" ]; then
            INDEX_JS="./extras/basic_example/public/scripts/index.js"
cat <<EOF >tmp.txt
var config = {
    rtcConfiguration: {
        iceServers: [{
            urls: [
            "stun:stun.l.google.com:19302"
            ]
        }, {
            urls: [
            "turn:_turn_HOST_:_turn_PORT_?transport=udp"
            ],
            credential: "_turn_PASSWORD_",
            username: "_turn_USERNAME_"
        }]
    }
};
EOF
            sed -i -e 's/_turn_HOST_/'"$TURN_HOST"'/g' tmp.txt
            sed -i -e 's/_turn_PORT_/'"$TURN_PORT"'/g' tmp.txt
            sed -i -e 's/_turn_USERNAME_/'"$TURN_USERNAME"'/g' tmp.txt
            sed -i -e 's/_turn_PASSWORD_/'"$TURN_PASSWORD"'/g' tmp.txt
            sed -i -e '/var conference/r tmp.txt' $INDEX_JS
            sed -i -e 's/ConferenceClient()/ConferenceClient(config)/g' $INDEX_JS
            rm tmp.txt
        fi
        ;;
esac

if [ -n "$LOGLEVEL" ]; then
    case $INSTANCE_TYPE in
        "nuve" | "cluster_manager" | "portal")
            LOGCONF_FILE="./${INSTANCE_TYPE}/log4js_configuration.json"
            sed -i -e 's/INFO/'"$LOGLEVEL"'/g' $LOGCONF_FILE
            ;;
        "audio" | "video" | "conference" | "webrtc" | "streaming" | "recording" | "sip")
            LOGCONF_FILE="./${INSTANCE_TYPE}_agent/log4js_configuration.json"
            sed -i -e 's/INFO/'"$LOGLEVEL"'/g' $LOGCONF_FILE
            ;;
    esac
fi

case $INSTANCE_TYPE in
    "nuve" | "sip_portal")
        echo "Running $INSTANCE_TYPE instance"
        cd $INSTANCE_TYPE
        $NODE_CMD ${INSTANCE_TYPE}.js
        ;;
    "cluster_manager" | "portal" | "management_console")
        echo "Running $INSTANCE_TYPE instance"
        cd $INSTANCE_TYPE
        $NODE_CMD .
        ;;
    "audio" | "video" | "conference" | "webrtc" | "streaming" | "recording" | "sip")
        echo "Running ${INSTANCE_TYPE}-agent instance"
        cd ${INSTANCE_TYPE}_agent
        export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:./lib
        $NODE_CMD . -U $INSTANCE_TYPE
        ;;
    "app")
        echo "Running ${INSTANCE_TYPE} instance"
        cd extras/basic_example/
        $NODE_CMD samplertcservice.js
        ;;
esac
    