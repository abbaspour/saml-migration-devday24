PLAN_FILE=auth0-is-new-sp.plan

LOG_LEVEL=''
TF=terraform

main: plan

init:
	@$(TF) init -upgrade

plan:
	@TF_LOG=$(LOG_LEVEL) $(TF) plan -out $(PLAN_FILE)

apply:
	@$(TF) apply -auto-approve $(PLAN_FILE)

show:
	$(TF) show

refresh:
	$(TF) refresh

validate:
	$(TF) validate

clean:
	rm $(PLAN_FILE)

lint:
	tflint

graph:
	$(TF) graph > graph.dot
	dot -Tsvg graph.dot -o graph.svg

.PHONY: clean plan
