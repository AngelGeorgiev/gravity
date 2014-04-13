def output():
    latitude = float(raw_input('Give me latitude: '))
    longitude = float(raw_input('Give me longitude: '))
    latitude = latitude // 10 * 10
    longitude = longitude // 10 * 10
    f = open('OUTPUT_10step.DAT', 'r')
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
