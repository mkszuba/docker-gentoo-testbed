FROM gentoo/stage3-amd64-hardened
MAINTAINER Marek Szuba <marecki@gentoo.org>

# This make.conf enables various non-default features required for
# ebuild stabilisation, and also disables default USE="bindist"
COPY files/etc/portage/make.conf /etc/portage/

# Initialise the Portage tree
# We will use subdirectories of /usr/local/portage to inject tested ebuilds
# into the container
COPY files/etc/portage/repos.conf/*.conf /etc/portage/repos.conf/
COPY files/portage-local-repo/layout.conf /usr/local/portage/metadata/
COPY files/portage-local-repo/repo_name /usr/local/portage/profiles/
RUN [ "emaint", "sync", "-a" ]

# If it is about anything in the base image, we are not interested
RUN [ "eselect", "news", "read", "--quiet", "all" ]
RUN [ "eselect", "news", "purge" ]

# Get the image in sync with the Portage tree + propagate use-flag changes
# introduced above
RUN [ "emerge", "-uUD", "--with-bdeps=y", "@world" ]
RUN [ "emerge", "@preserved-rebuild" ]
RUN [ "emerge", "--depclean" ]

RUN [ "emerge", "app-editors/vim", "app-portage/eix", "app-portage/gentoolkit" ]
RUN [ "eix-update" ]

CMD [ "/bin/bash" ]
