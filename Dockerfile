FROM golang:1.8-alpine
MAINTAINER Gerson Graciani

#Copies .vimrc to root
ADD root/ /root/
ADD etc/ /etc/
 
ENV GLIBC_VERSION=2.23-r3 

RUN \ 
#Adding GIT and BUILD Tools AND ncurses-dev
    apk --update add --no-cache --virtual=build-dependencies curl tmux irssi ctags wget ca-certificates git build-base ncurses-dev lua5.2-dev lua5.2-libs lua5.2 lua5.2-posix autoconf automake libtool libstdc++ \


 #Install glibc for alpine because golang -race depends on that
    && for pkg in glibc-${GLIBC_VERSION} glibc-bin-${GLIBC_VERSION} glibc-i18n-${GLIBC_VERSION}; do curl -sSL https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/${pkg}.apk -o /tmp/${pkg}.apk; done  \
    && apk add --allow-untrusted /tmp/*.apk  \
    && rm -v /tmp/*.apk  \
    && ( /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true )  \
    && echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh  \
    && /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib  \
    && echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf  \

#Getting Go Tools
	&& go get github.com/alecthomas/gometalinter \
	&& go get golang.org/x/tools/cmd/guru \
	&& go get github.com/klauspost/asmfmt/cmd/asmfmt \
	&& go get github.com/fatih/motion \
	&& go get github.com/zmb3/gogetdoc \
	&& go get github.com/josharian/impl \
    && go get golang.org/x/tools/cmd/godoc \
    && go get github.com/nsf/gocode \
    && go get golang.org/x/tools/cmd/goimports \
    && go get github.com/rogpeppe/godef \
    && go get golang.org/x/tools/cmd/oracle \
    && go get golang.org/x/tools/cmd/gorename \
    && go get github.com/golang/lint/golint \
    && go get github.com/kisielk/errcheck \
    && go get github.com/jstemmer/gotags \
    && go get github.com/govend/govend \
    && go get -u github.com/golang/protobuf/protoc-gen-go \
    
#Compiling Google Protobuf
    && cd /tmp \
	&& wget https://github.com/google/protobuf/releases/download/v3.0.0-beta-3/protobuf-cpp-3.0.0-beta-3.tar.gz \
    && tar xvzf protobuf-cpp-3.0.0-beta-3.tar.gz  \
    && cd protobuf-3.0.0-beta-3/ \
    && ./autogen.sh \
    && ./configure \
    && make && make check && make install && make clean \
    
#Compiling VIM
	#Helps configure find lua headers and libraries
	&& ln -s /usr/include/lua5.2 /usr/include/lua \
	&& ln -s /usr/lib/lua5.2/liblua-5.2.so.0 /usr/lib/liblua.so.0 \
	&& ln -s /usr/lib/lua5.2/liblua-5.2.so.0.0.0 /usr/lib/liblua.so.0.0.0 \
	#Downloads vim
    && cd /tmp \
    && git clone https://github.com/vim/vim.git \
	#Compiles vim with lua support
    && cd vim \
    && ./configure --with-features=huge --enable-luainterp=dynamic --enable-gui=no --without-x --prefix=/usr \
    && make VIMRUNTIMEDIR=/usr/share/vim/vim74 \
    && make install \
	&& cp /usr/bin/vim /usr/bin/vi \

#CLEANUP
    && apk del libtool automake autoconf build-base \
    && rm -rf /var/cache/apk/* /tmp/* /var/tmp/*  /go/src/* \

#CONFIG VIM
    && mkdir -p /root/.vim/bundle \
    && cd /root/.vim/bundle \
    && git clone --depth 1 https://github.com/gmarik/Vundle.vim.git \
    && git clone --depth 1 https://github.com/fatih/vim-go.git \
    && git clone --depth 1 https://github.com/majutsushi/tagbar.git \
    && git clone --depth 1 https://github.com/Shougo/neocomplete.vim.git \
    && git clone --depth 1 https://github.com/bling/vim-airline.git \
    && git clone --depth 1 https://github.com/tpope/vim-fugitive.git \
    && git clone --depth 1 https://github.com/jistr/vim-nerdtree-tabs.git \
    && git clone --depth 1 https://github.com/mbbill/undotree.git \
    && git clone --depth 1 https://github.com/Lokaltog/vim-easymotion.git \
    && git clone --depth 1 https://github.com/scrooloose/nerdcommenter.git \
    && git clone --depth 1 https://github.com/scrooloose/nerdtree.git \
    && vim +PluginInstall +qall \

#CLEANUP
    && rm -rf */.git
