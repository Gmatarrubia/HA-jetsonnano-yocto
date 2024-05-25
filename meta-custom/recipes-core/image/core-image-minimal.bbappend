require conf/include/assistant-user-common.inc

inherit extrausers

EXTRA_USERS_PARAMS = " \
	groupadd -g 1011 users;\
	useradd \
	-u 1010 \
	--home ${ASSISTANT_USER_PATH} \
	--groups users \
	--user-group ${ASSISTANT_USER_NAME};\
"
