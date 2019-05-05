
CODE_BUCKET=hideitbot.code.erphe.us
STACK_NAME=hideitbot

.PHONY: deploy down
all: deploy

deploy: src/deps/install-python-deps
	aws cloudformation package --template deploy/template.yaml --s3-bucket $(CODE_BUCKET) --output-template-file deploy/generated-stack.yaml
	aws cloudformation deploy --template-file deploy/generated-stack.yaml --stack-name $(STACK_NAME) --capabilities CAPABILITY_IAM --parameter-overrides $$(sed '/^[[:blank:]]*#/d;s/#.*//' ./deploy.env | sed ':a;N;$!ba;s/\n/ /g' )
	#aws cloudformation describe-stacks --stack-name $(STACK_NAME) --query 'Stacks[0].Outputs'
	deploy/setUpWebHook.sh $(STACK_NAME)

down:
	aws cloudformation delete-stack --stack-name $(STACK_NAME)


src/deps/install-python-deps: src/requirements.txt
	docker run -it --rm -v $(PWD)/src:/src python:3.6 pip install -r /src/requirements.txt -t /src/deps
	date > $@  # Write to a file to prevent executions of this target unless requirements.txt changes










