def repeat_fibonacci_style_for(attempts)
  done = false
  attempt = 1
  last_wait = 0
  wait = 1
  while !done && (attempt <= attempts)
    done = yield
    attempt += 1
    sleep wait
    last_wait, wait = wait, last_wait + wait
  end
  done
end

def wait_for_port(host, port, attempts = 15)
  puts("Waiting for port #{port} ... ", false)
  start = Time.now
  done = repeat_fibonacci_style_for(attempts) do
    system("bash -c \"exec 5<>'/dev/tcp/#{host}/#{port}'\"")
  end
  if done
    puts('connected in %0.2f seconds' % (Time.now - start))
  else
    puts('timeout')
  end
  done
end
