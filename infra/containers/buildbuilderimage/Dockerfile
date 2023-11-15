FROM quay.io/toolbx-images/ubuntu-toolbox:22.04
RUN apt-get -y update
RUN curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes
RUN git config --global http.sslVerify false
ENV PATH "$PATH:/nix/var/nix/profiles/default/bin"
RUN `#export PATH=$PATH:/root/.nix-profile/bin` ; \
  nix-daemon & sleep 1; \
    nix-env -iA nixpkgs.nodejs && \
    nix-env -iA nixpkgs.buildah && \
    nix-env -iA nixpkgs.podman `# For some reason buildah invokes podman for something involving image pushing??`
RUN mkdir -p /etc/containers
RUN echo '{"default":[{"type":"insecureAcceptAnything"}],"transports":{"docker-daemon":{"":[{"type":"insecureAcceptAnything"}]}}}' > /etc/containers/policy.json
RUN `#TODO flip this?` echo '[registries]\n[registries.search]\nregistries = ["docker.io", "quay.io"]\n' > /etc/containers/registries.conf







