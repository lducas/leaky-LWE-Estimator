import time
from multiprocessing import Process, Queue

return_queue = Queue()


def test_process(i, return_queue):
    time.sleep(4 * i + 1)
    return_queue.put(3 * i + 2)


def map_drop(nb, threads, f, aargs, max_drop=0):
    processes = []

    def ff(i, args, return_queue):
        for trial in range(10):
            r = f(i + 2**16 * trial, args)
            return_queue.put(r)
            return
            # except:
            #     pass
            # print "FAILED 10 TIMES"

    for i in range(threads):
        process = Process(target=ff, args=(i, aargs, return_queue))
        processes.append(process)
        process.start()

    ret = []
    for i in range(threads, nb + threads):
        ret.append(return_queue.get())  # this is blocking
        if len(ret) == nb:
            break
        if i < nb + max_drop:
            process = Process(target=ff, args=(i, aargs, return_queue))
            processes.append(process)
            process.start()

    for process in processes:
        if process.is_alive():
            process.terminate()

    if len(ret) != nb:
        print(len(ret), nb)
        raise ValueError("Something went wrong.")
    return ret
