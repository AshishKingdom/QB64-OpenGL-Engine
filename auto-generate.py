# @Author: Ashish
# this python script generates engine_method_noerror.bas

if __name__ == "__main__":
    f = open("engine_method.bas", "r")
    code_lines = f.read().split('\n')
    f.close()
    f = open("engine_method_noerror.bas", "w")
    k = True
    for i in code_lines:
        if i.strip()=="'@debug-part:start" or i.strip()=="'@debug-part:end":
            k = not k
            continue
        if k:
            f.write(i+'\n')
    print("success")