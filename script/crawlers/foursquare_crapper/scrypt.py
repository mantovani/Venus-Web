#!/usr/bin/python

import foursquare
import codecs
import sys
import json
import re

UTF8Writer = codecs.getwriter('utf8')
sys.stdout = UTF8Writer(sys.stdout)

client = foursquare.Foursquare(client_id='DKZEL3H4R3GNHC2XAKQPZLEIOLUU1IEPPD55PDGEJK5G5UI4', client_secret='FTRUQ3RLDS412R21CG3DUGBRR3YPQH4XAH0B1N3HTNXN2OIF')

holder = 'lon,lat'
lon,lat = -23.426179,-46.795560
xlon,xlat = lon,lat
lon_range,lat_range = 300,500
count = 1 
total = lon_range * lat_range
for x in range(1,lon_range):
	xlon -= 0.001
	for y in range (1,lat_range):
		xlat += 0.001
		ll = holder
		ll = re.sub('lon',str(xlon),holder)
		ll = re.sub('lat',str(xlat),ll)
		print >> sys.stderr,str(round(count*100.0/total,3)) + '% ' + str(count) + ' of ' + str(total) + '[' + ll + ']'
		count += 1
		try:
			results = client.venues.search(params={'ll': ll,'limit':'50','radius':'1000'})
			for result in results['venues']:
				print json.dumps(result)
		except:
			print >> sys.stderr, sys.exc_info()[0]
	xlat = lat
