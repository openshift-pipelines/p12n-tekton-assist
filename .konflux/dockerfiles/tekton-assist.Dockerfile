ARG GO_BUILDER=registry.access.redhat.com/ubi9/go-toolset:1.25
ARG RUNTIME=registry.access.redhat.com/ubi9/ubi-minimal:latest

FROM $GO_BUILDER AS builder

WORKDIR /go/src/github.com/openshift-pipelines/tekton-assist
COPY upstream .
COPY .konflux/patches patches/
COPY head /tmp/HEAD
RUN set -e; for f in patches/*.patch; do echo ${f}; [[ -f ${f} ]] || continue; git apply ${f}; done

ENV GOEXPERIMENT=strictfipsruntime
RUN go build -ldflags="-X 'knative.dev/pkg/changeset.rev=$(cat /tmp/HEAD)'" -mod=vendor -tags disable_gcp,strictfipsruntime -v -o /tmp/tekton-assist \
    ./cmd/tkn-assist

FROM $RUNTIME
ARG VERSION=next

COPY --from=builder /tmp/tekton-assist /ko-app/tekton-assist

LABEL \
    com.redhat.component="openshift-pipelines-tekton-assist-rhel9-container" \
    cpe="cpe:/a:redhat:openshift_pipelines:next::el9" \
    description="Red Hat OpenShift Pipelines tekton-assist tekton-assist" \
    io.k8s.description="Red Hat OpenShift Pipelines tekton-assist tekton-assist" \
    io.k8s.display-name="Red Hat OpenShift Pipelines tekton-assist tekton-assist" \
    io.openshift.tags="tekton,openshift,tekton-assist,tekton-assist" \
    maintainer="pipelines-extcomm@redhat.com" \
    name="openshift-pipelines/pipelines-tekton-assist-rhel9" \
    summary="Red Hat OpenShift Pipelines tekton-assist tekton-assist" \
    version="next"

RUN microdnf install -y shadow-utils
RUN groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot nonroot
USER 65532

ENTRYPOINT ["/ko-app/tekton-assist"]
