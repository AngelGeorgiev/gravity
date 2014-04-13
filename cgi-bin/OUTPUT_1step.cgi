import cgitb
cgitb.enable()

def output():  
    form = cgi.FieldStorage()
    latitude = float(form.getvalue("latitude"))
    longitude = float(form.getvalue("longitude"))
    latitude = latitude // 1
    longitude = longitude // 1
    f = open('OUTPUT_1step.DAT', 'r')
    for line in f:
        xlat = float(line[:11])
        xlng = float(line[12:24])
        xgravity = float(line[25:])
        if (xlat == latitude) & (xlng == longitude):
            print xgravity


    f.close()

def main():
    output()

if __name__ == '__main__':
    main()
