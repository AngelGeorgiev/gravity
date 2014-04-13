def input():
    f = open('INPUT.DAT', 'w')
    print f
    for x in xrange(0,360):
        for y in xrange(0,360):
            s = str(x)+"  "+str(y)
            f.write(s)
            f.write('\n')

    f.close()

def main():
    input()

if __name__ == '__main__':
    main()
