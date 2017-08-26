FROM ubuntu:14.04

RUN apt-get -qq update && apt-get -qqy upgrade && \
apt-get -y install software-properties-common \
python-software-properties inotify-tools debconf-utils && \
apt-get -y install git wget unzip default-jre openjdk-7-jre php5

WORKDIR /root

RUN wget http://files.basex.org/releases/8.5.3/BaseX853.zip
RUN unzip BaseX853.zip
RUN mkdir openinfoman
RUN cp -R basex/* openinfoman/
RUN cp basex/.basexhome openinfoman/

RUN mkdir openinfoman/repo-src
RUN git clone https://github.com/openhie/openinfoman openinfomangh
RUN cp openinfomangh/repo/* openinfoman/repo-src/
RUN cp -R openinfomangh/resources openinfoman/
RUN cp ~/openinfomangh/webapp/*xqm ~/openinfoman/webapp
RUN mkdir -p ~/openinfoman/webapp/static
RUN cp -R ~/openinfomangh/webapp/static/* ~/openinfoman/webapp/static
RUN ln -s ~/openinfoman/bin/basex /usr/local/bin

RUN basex -Vc "CREATE DATABASE provider_directory"

RUN echo "module namespace csd_webconf = 'https://github.com/openhie/openinfoman/csd_webconf';\n\
declare variable \$csd_webconf:db :=  'provider_directory';\n\
declare variable \$csd_webconf:baseurl :=  '';\n\
declare variable \$csd_webconf:remote_services := ();\n\
" > $HOME/openinfoman/repo-src/generated_openinfoman_webconfig.xqm

RUN basex -Vc "REPO INSTALL http://files.basex.org/modules/expath/functx-1.0.xar"

WORKDIR /root/openinfoman/repo-src
RUN basex -Vc "repo install "generated_openinfoman_webconfig.xqm""

# Change shell to bash to interpret array syntax
SHELL ["/bin/bash", "-c"]

RUN declare -a arr=("csd_webapp_ui.xqm" "csd_base_library.xqm" "csd_base_library_updating.xqm"   "csd_base_stored_queries.xqm"  "csd_document_manager.xqm"  "csd_load_sample_directories.xqm"  "csd_query_updated_services.xqm"  "csd_poll_service_directories.xqm"  "csd_local_services_cache.xqm"  "csd_merge_cached_services.xqm"  "csr_processor.xqm"  "svs_load_shared_value_sets.xqm"  "async_fake.xqm"); \
for i in "${arr[@]}"; do basex -Vc "repo install $i"; done
RUN basex -Vc "RUN $HOME/openinfoman/resources/scripts/init_db.xq"

WORKDIR /root/openinfoman
RUN declare -a arr=("stored_query_definitions/facility_search.xml" "stored_query_definitions/adhoc_search.xml" "stored_query_definitions/service_search.xml" "stored_query_definitions/organization_search.xml" "stored_query_definitions/provider_search.xml" "stored_query_definitions/modtimes.xml" "stored_updating_query_definitions/service_create.xml" "stored_updating_query_definitions/mark_duplicate.xml" "stored_updating_query_definitions/simple_merge.xml" "stored_updating_query_definitions/mark_potential_duplicate.xml" "stored_updating_query_definitions/delete_potential_duplicate.xml" "stored_updating_query_definitions/organization_create.xml" "stored_updating_query_definitions/provider_create.xml" "stored_updating_query_definitions/facility_create.xml" "stored_updating_query_definitions/delete_duplicate.xml" "stored_updating_query_definitions/merge_by_identifier.xml" "stored_updating_query_definitions/extract_hierarchy.xml");\
for i in "${arr[@]}"; do resources/scripts/install_stored_function.php resources/$i; done

WORKDIR /root/openinfoman/resources/shared_value_sets
RUN declare -a arr=("1.3.6.1.4.1.21367.200.101" "1.3.6.1.4.1.21367.200.102" "1.3.6.1.4.1.21367.200.103" "1.3.6.1.4.1.21367.200.104" "1.3.6.1.4.1.21367.200.105" "1.3.6.1.4.1.21367.200.106" "1.3.6.1.4.1.21367.200.108" "1.3.6.1.4.1.21367.200.109" "1.3.6.1.4.1.21367.200.110" "2.25.1098910207106778371035457739371181056504702027035" "2.25.17331675369518445540420660603637128875763657" "2.25.18630021159349753613449707959296853730613166189051" "2.25.259359036081944859901459759453974543442705863430576" "2.25.265608663818616228188834890512310231251363785626032" "2.25.309768652999692686176651983274504471835.999.400" "2.25.309768652999692686176651983274504471835.999.401" "2.25.309768652999692686176651983274504471835.999.402" "2.25.309768652999692686176651983274504471835.999.403" "2.25.309768652999692686176651983274504471835.999.404" "2.25.309768652999692686176651983274504471835.999.405" "2.25.309768652999692686176651983274504471835.999.406" "2.25.9830357893067925519626800209704957770712560");\
for i in "${arr[@]}"; do basex -q"import module namespace svs_lsvs = 'https://github.com/openhie/openinfoman/svs_lsvs';' (svs_lsvs:load($i))'" ; done

# Temporary fix for bug
WORKDIR /root/openinfoman/repo/com/github/openhie/openinfoman
RUN sed -i "s|concat(file:current-dir() ,'../resources/shared_value_sets/')|file:resolve-path('resources/shared_value_sets/', file:current-dir())|" svs_lsvs.xqm

SHELL ["/bin/sh", "-c"]

# Must switch back to this dir or paths will fail
WORKDIR /root/openinfoman

EXPOSE 8984 8985 1984

ENTRYPOINT ["/root/openinfoman/bin/basexhttp"]
