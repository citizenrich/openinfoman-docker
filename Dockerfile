FROM ubuntu:latest

RUN apt-get -qq update && apt-get -qqy upgrade

RUN apt-get -y install software-properties-common python-software-properties inotify-tools debconf-utils
RUN apt-get -y install git wget unzip default-jre openjdk-8-jre

WORKDIR /root/basex

RUN wget --quiet http://files.basex.org/releases/8.6.4/BaseX864.zip
RUN unzip BaseX864.zip -d ~/
RUN touch ~/basex/.basexhome
RUN chmod 777 -R ~/basex
RUN ln -s ~/basex/bin/basex /usr/local/bin

WORKDIR /root

RUN git clone https://github.com/openhie/openinfoman

RUN basex -Vc "REPO INSTALL http://files.basex.org/modules/expath/functx-1.0.xar"

WORKDIR ./openinfoman/repo

RUN basex -Vc "repo install csd_base_library.xqm"
RUN basex -Vc "repo install csd_base_library_updating.xqm"
RUN basex -Vc "repo install csd_base_stored_queries.xqm"
RUN basex -Vc "repo install csd_webapp_config.xqm"
RUN basex -Vc "repo install csd_webapp_ui.xqm"
RUN basex -Vc "repo install csd_document_manager.xqm"
RUN basex -Vc "repo install csd_load_sample_directories.xqm"
RUN basex -Vc "repo install csd_query_updated_services.xqm"
RUN basex -Vc "repo install csd_poll_service_directories.xqm"
RUN basex -Vc "repo install csd_local_services_cache.xqm"
RUN basex -Vc "repo install csd_merge_cached_services.xqm"
RUN basex -Vc "repo install csr_processor.xqm"
RUN basex -Vc "repo install svs_load_shared_value_sets.xqm"

RUN basex -Vc "CREATE DATABASE provider_directory"

RUN cp -a ~/openinfoman/webapp/*xqm ~/basex/webapp
RUN mkdir -p ~/basex/webapp/static
RUN cp -a ~/openinfoman/webapp/static/* ~/basex/webapp/static

EXPOSE 8984 8985 1984

RUN mkdir -p ~/basex/resources/stored_query_definitions
RUN mkdir -p ~/basex/resources/stored_updating_query_definitions
RUN ln -sf ~/openinfoman/resources/stored_query_definitions/* ~/basex/resources/stored_query_definitions
RUN ln -sf ~/openinfoman/resources/stored_updating_query_definitions/* ~/basex/resources/stored_updating_query_definitions

RUN mkdir -p ~/basex/resources/shared_value_sets
RUN ln -sf ~/openinfoman/resources/shared_value_sets/* ~/basex/resources/shared_value_sets

RUN mkdir -p ~/basex/resources/service_directories
RUN ln -sf ~/openinfoman/resources/service_directories/* ~/basex/resources/service_directories

RUN mkdir -p ~/basex/resources/test_docs
# likely to be deprecated
RUN ln -sf ~/openinfoman/resources/test_docs/* ~/basex/resources/test_docs

RUN ln -sf ~/openinfoman/resources/SVS.xsd ~/basex/resources/
RUN ln -sf ~/openinfoman/resources/CSD.xsd ~/basex/resources/
RUN ln -sf ~/openinfoman/resources/doc_careServiceFunctions.xsl ~/basex/resources/

# install packages

# openinfoman-hwr
WORKDIR /root
RUN git clone https://github.com/openhie/openinfoman-hwr
RUN ln -sf ~/openinfoman-hwr/resources/stored_query_definitions/* ~/basex/resources/stored_query_definitions
RUN ln -sf ~/openinfoman-hwr/resources/stored_updating_query_definitions/* ~/basex/resources/stored_updating_query_definitions

# openinfoman-csv
RUN git clone https://github.com/openhie/openinfoman-csv
WORKDIR /root/openinfoman-csv/repo
RUN basex -Vc "REPO INSTALL openinfoman_csv_adapter.xqm"

# opeinfoman-ldif

# error
# Stopped at /root/basex/webapp/openinfoman_ldif_adapter_bindings.xqm, 113/29:
# [XPST0017] Unknown function: Q{https://github.com/openhie/openinfoman/csd_webconf}wrapper (similar: Q{http://basex.org/modules/web-page}wrapper).

# WORKDIR /root
# RUN git clone https://github.com/openhie/openinfoman-ldif
# WORKDIR /root/openinfoman-ldif/repo
# RUN basex -Vc "REPO INSTALL openinfoman_ldif_adapter.xqm"
# RUN ln -sf ~/openinfoman-ldif/resources/stored_query_definitions/* ~/basex/resources/stored_query_definitions
# RUN ln -s ~/openinfoman-ldif/webapp/openinfoman_ldif_adapter_bindings.xqm ~/basex/webapp/

# openinfoman-r

# error: Stopped at /root/basex/webapp/openinfoman_r_adapter_bindings.xqm, 56/30:
# [XPST0017] Unknown function: Q{https://github.com/openhie/openinfoman/csd_webconf}wrapper.

# WORKDIR /root
# RUN git clone https://github.com/openhie/openinfoman-r
# WORKDIR /root/openinfoman-r/repo
# RUN basex -Vc "REPO INSTALL openinfoman_r_adapter.xqm"
# RUN ln -sf ~/openinfoman-r/resources/stored_query_definitions/* ~/basex/resources/stored_query_definitions
# RUN ln -s ~/openinfoman-r/webapp/openinfoman_r_adapter_bindings.xqm ~/basex/webapp/

# openinfoman-dhis2
WORKDIR /root
RUN git clone https://github.com/openhie/openinfoman-dhis
WORKDIR /root/openinfoman-dhis/repo
RUN basex -Vc "REPO INSTALL dxf_1_0.xqm"
RUN basex -Vc "REPO INSTALL dxf2csd.xqm "
RUN ln -sf ~/openinfoman-dhis/resources/stored_query_definitions/* ~/basex/resources/stored_query_definitions
RUN ln -sf ~/openinfoman-dhis/resources/stored_updating_query_definitions/* ~/basex/resources/stored_updating_query_definitions
RUN ln -sf ~/openinfoman-dhis/webapp/openinfoman_dhis2_bindings.xqm ~/basex/webapp
RUN ln -s ~/openinfoman-dhis/resources/service_directories/* ~/basex/resources/service_directories/

# openinfomab-fhir

# error: Java function org.intrahealth.hapi_transformer:new#0 is unknown

# WORKDIR /root
# RUN git clone https://github.com/openhie/openinfoman-fhir
# WORKDIR /root/openinfoman-fhir/repo
# RUN basex -Vc "REPO INSTALL openinfoman_fhir_adapter.xqm"
# RUN ln -sf ~/openinfoman-fhir/resources/stored_query_definitions/* ~/basex/resources/stored_query_definitions
# RUN ln -sf ~/openinfoman-fhir/webapp/openinfoman_fhir_bindings.xqm ~/basex/webapp


# can bash into container and use the usual if uncommenting entrypoint
# cd ~/basex/bin && ./basexhttp &

ENTRYPOINT ["/root/basex/bin/basexhttp"]
# CMD ["/root/basex/bin/basexhttp", "-d"] <- for debugging
