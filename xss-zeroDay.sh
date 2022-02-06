#!/bin/sh
#
# Run as root.
#   will flush the cache so no mailboxd restart is necessary.
#   will only patch once
#
# patch XSS zero day ZBUG-2642 on Feb 4, 2022 as documented here:
#   https://forums.zimbra.org/viewtopic.php?f=15&t=70382
# patched pulled from here (Jholder):
#   https://github.com/Zimbra/zm-web-client/pull/672/commits/76c23a937d2ab40cdfafad1d7a3546bfbf354704
#

multiDay=/opt/zimbra/jetty_base/webapps/zimbra/WEB-INF/tags/calendar/multiDay.tag
grep escapeXml $multiDay | grep -q newAppt
if [ $? -eq 1 ]; then
   # backup of original
   cp $multiDay $multiDay.bak

   echo "Appying patch to $multiDay"

#
# Want to do this:
#     a href="${newAppt}" 
# to
#     a href="${fn:escapeXml(newAppt)}"
#
perl - $multiDay <<'__HERE__' > $multiDay.out
my $match_str = quotemeta('href="${newAppt}');
my $replace_str = 'href="${fn:escapeXml(newAppt)}';
while (<>) {
      s/$match_str/$replace_str/g;
      print $_;
}
__HERE__

   #
   if [ -s $multiDay.out ]; then
      mv $multiDay.out $multiDay
      chown zimbra:zimbra $multiDay
      chmod 644 $multiDay
      echo "flushing cache... no mailbox restart required"
      su - zimbra -c "zmprov fc -a all"
   fi

else
  echo "nothing to patch"
fi

# -------- monthView.tag --------------
monthView=/opt/zimbra/jetty_base/webapps/zimbra/WEB-INF/tags/calendar/monthView.tag
grep monthZoomUrl $monthView | grep escapeXml | grep -q dayClick
if [ $? -eq 1 ]; then
   # backup of original
   cp $monthView $monthView.bak

   echo "Appying patch to $monthView"

#
# Want to do this:
#    ${monthZoomUrl}
# to
#    ${fn:escapeXml(monthZoomUrl)}
perl - $monthView <<'__HERE__' > $monthView.out
my $match_str = quotemeta('${monthZoomUrl}');
my $replace_str = '${fn:escapeXml(monthZoomUrl)}';
while (<>) {
      s/$match_str/$replace_str/g;
      print $_;
}
__HERE__

   #
   if [ -s $monthView.out ]; then
      mv $monthView.out $monthView
      chown zimbra:zimbra $monthView
      chmod 644 $monthView
      echo "flushing cache... no mailbox restart required"
      su - zimbra -c "zmprov fc -a all"
   fi

else
  echo "nothing to patch"
fi
