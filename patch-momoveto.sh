#!/bin/sh
#
#  Security patch 8.8.15 (July 12, 2023)
#
momoveto=/opt/zimbra/jetty/webapps/zimbra/m/momoveto
#momoveto=/tmp/momoveto

grep -q 'fn:escapeXml(param.st)' $momoveto
if [ $? -eq 1 ]; then
   cp $momoveto $momoveto.bak

   echo "Appying patch to $momoveto"
#     <input name="st" type="hidden" value="${param.st}"/>
   sed -i -e 's,    <input name="st" type="hidden" value="${param.st}"/>,    <input name="st" type="hidden" value="${fn:escapeXml(param.st)}"/>,g' $momoveto
else
   echo "nothing to patch"
fi