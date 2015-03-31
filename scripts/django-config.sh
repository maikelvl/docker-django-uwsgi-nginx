#!/bin/bash

function find_replace_add_string_to_file() {
	find="$1"
	replace="$2"
	replace_escaped="${2//\//\\/}"
	file="$3"
	label="$4"
	if grep -q ";$find" "$file" # The exit status is 0 (true) if the name was found, 1 (false) if not
	then
		action="Uncommented"
		sed -i "s/;$find/$replace_escaped/" "$file"
	elif grep -q "#$find" "$file" # The exit status is 0 (true) if the name was found, 1 (false) if not
	then
		action="Uncommented"
		sed -i "s/#$find/$replace_escaped/" "$file"
	elif grep -q "$replace" "$file"
	then
		action="Already set"
	elif grep -q "$find" "$file"
	then
		action="Overwritten"
		sed -i "s/$find/$replace_escaped/" "$file"
	else
		action="Added"
		echo -e "\n$replace\n" >> "$file"
	fi
	echo " ==> Setting $label ($action) [$replace in $file]"
}

function fix_python_exec_path()
{
	for file in /project/bin/*
	do
		if [ ! -f $file ]
		then
			continue
		fi
		find="\#\!/project/bin/python$PYTHON_VERSION"
		find2="\#\!/project/bin/python"
		find_escaped="${find//\//\\/}"
		find_escaped2="${find2//\//\\/}"
		replace="#!/usr/bin/env python"
		replace_escaped="${replace//\//\\/}"
		sed -i "s/$find_escaped/$replace_escaped/" "$file"
		sed -i "s/$find_escaped2/$replace_escaped/" "$file"
	done
}

# install django, normally you would remove this step because your project would already
# be installed in the code/app/ directory

if [ ! -d /project ]
then
	mkdir -p /project
fi

if [ ! -f /project/requirements.txt ]
then
	cp /conf/requirements.txt /project/requirements.txt
fi

virtualenv /project --python "python$PYTHON_VERSION"
fix_python_exec_path

echo -e '#!/bin/bash' > /root/.bashrc
echo -e 'export PATH="/project/bin:$PATH"' >> /root/.bashrc
echo -e 'source /project/bin/activate' >> /root/.bashrc
chmod +x /project/bin/*
chmod +x /root/.bashrc

find_replace_add_string_to_file "VIRTUAL_ENV=.*" "VIRTUAL_ENV=\"/project\";if [ -d ];then VIRTUAL_ENV=\"\$PWD\";fi" /project/bin/activate "Modify activate script" 

source /root/.bashrc
/project/bin/pip install -r /project/requirements.txt
fix_python_exec_path

if [ ! -d /project/$CODE_DIR ]
then
	mkdir -p /project/$CODE_DIR
	/project/bin/django-admin.py startproject $PROJECT_NAME /project/$CODE_DIR
	fix_python_exec_path
fi

# if [ ! -d /project/$CODE_DIR/$PROJECT_NAME/$APP_NAME ]
# then
# 	if [ $APP_TEMPLATE ]
# 	then
# 		template="--template=$APP_TEMPLATE"
# 	fi
# 	/project/bin/django-admin.py startapp $template $APP_NAME /project/$CODE_DIR/$PROJECT_NAME
# 	fix_python_exec_path
# fi

if [ $TIMEZONE ] && [ -f /project/$CODE_DIR/$PROJECT_NAME/settings.py ]
then
	find_replace_add_string_to_file "TIME_ZONE = .*" "TIME_ZONE = '$TIMEZONE'" /project/$CODE_DIR/$PROJECT_NAME/settings.py "Set $CODE_DIR/$PROJECT_NAME Timezone"
fi

echo "code directory: $CODE_DIR"
echo "project: $CODE_DIR/$PROJECT_NAME"

if [ ! -d /project/static/admin ]
then
	mkdir -p /project/static
	python_dir=$(ls -r /project/lib | head -n 1)
	if [ -d /project/lib/$python_dir/site-packages/django/contrib/admin/static/admin ]
	then
		cp -r /project/lib/$python_dir/site-packages/django/contrib/admin/static/admin /project/static/admin
	else
		echo "No static files for admin found: /project/lib/$python_dir/site-packages/django/contrib/admin/static/admin"
	fi
fi
