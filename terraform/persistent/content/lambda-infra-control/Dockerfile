FROM public.ecr.aws/lambda/python:3.13

COPY app.py control.py github_api.py ${LAMBDA_TASK_ROOT}/

CMD ["app.handler"]
