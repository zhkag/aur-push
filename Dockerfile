FROM archlinux:base

RUN pacman -Syu --noconfirm
RUN pacman -S --noconfirm --needed --overwrite '*' \
      openssh sudo \
      git fakeroot binutils gcc awk xz less \
      libarchive bzip2 coreutils file findutils \
      gettext grep gzip sed ncurses util-linux \
      pacman-contrib

ADD script /aurpush
ADD aur /aurpush/aur

ENTRYPOINT ["/aurpush/entrypoint.sh"]
