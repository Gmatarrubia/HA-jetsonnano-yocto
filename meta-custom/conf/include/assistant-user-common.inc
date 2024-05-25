
# Common variables
ASSISTANT_USER_NAME = "assistant"
ASSISTANT_USER_PATH = "/home/${ASSISTANT_USER_NAME}/"

inherit useradd

USERADD_PACKAGES = "${PN}"
USERADD_PARAM:${PN} = " \
	--home ${ASSISTANT_USER_PATH} \
	--groups users \
	--user-group ${ASSISTANT_USER_NAME}\
"
