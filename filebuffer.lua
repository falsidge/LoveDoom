local bit32 = bit32 or bit or require("bit32")
local unpack, floor = table.unpack or unpack, math.floor
local function open_file_buffer(filename)    -- open file for read-only, returns InputBufferObject

    local input_buffer_object = {}
    local intel_byte_order = true
    local file = assert(io.open(filename,  'rb'))
    local file_size = assert(file:seek'end')
    assert(file:seek'set')
 
    input_buffer_object.file_size = file_size
 
    local user_offset = 0
 
    function input_buffer_object.jump(offset)
       user_offset = offset
       return input_buffer_object
    end
 
    function input_buffer_object.skip(delta_offset)
       user_offset = user_offset + delta_offset
       return input_buffer_object
    end
 
    function input_buffer_object.get_offset()
       return user_offset
    end
 
    local file_blocks = {}   -- [block_index] = {index=block_index, data=string, more_fresh=obj_ptr, more_old=obj_ptr}
    local cached_blocks = 0  -- number if block indices in use in the array file_blocks
    local chain_terminator = {}
    chain_terminator.more_fresh = chain_terminator
    chain_terminator.more_old = chain_terminator
    local function remove_from_chain(object_to_remove)
       local more_fresh_object = object_to_remove.more_fresh
       local more_old_object = object_to_remove.more_old
       more_old_object.more_fresh = more_fresh_object
       more_fresh_object.more_old = more_old_object
    end
    local function insert_into_chain(object_to_insert)
       local old_freshest_object = chain_terminator.more_old
       object_to_insert.more_fresh = chain_terminator
       object_to_insert.more_old = old_freshest_object
       old_freshest_object.more_fresh = object_to_insert
       chain_terminator.more_old = object_to_insert
    end
    local function get_file_block(block_index)
       -- blocks are aligned to 32K boundary, indexed from 0
       local object = file_blocks[block_index]
       if not object then
          if cached_blocks < 3 then
             cached_blocks = cached_blocks + 1
          else
             local object_to_remove = chain_terminator.more_fresh
             remove_from_chain(object_to_remove)
             file_blocks[object_to_remove.index] = nil
          end
          local block_offset = block_index * 32*1024
          local block_length = math.min(32*1024, file_size - block_offset)
          assert(file:seek('set', block_offset))
          local content = file:read(block_length)
          assert(#content == block_length)
          object = {index = block_index, data = content}
          insert_into_chain(object)
          file_blocks[block_index] = object
       elseif object.more_fresh ~= chain_terminator then
          remove_from_chain(object)
          insert_into_chain(object)
       end
       return object.data
    end
 
    function input_buffer_object.close()
       file_blocks = nil
       chain_terminator = nil
       file:close()
    end
 
    function input_buffer_object.read_string(length)
       assert(length >= 0, 'negative string length')
       assert(user_offset >= 0 and user_offset + length <= file_size, 'attempt to read beyond the file boundary')
       local str, arr = ''
       while length > 0 do
          local offset_inside_block = user_offset % (32*1024)
          local part_size = math.min(32*1024 - offset_inside_block, length)
          local part = get_file_block(floor(user_offset / (32*1024))):sub(1 + offset_inside_block, part_size + offset_inside_block)
          user_offset = user_offset + part_size
          length = length - part_size
          if arr then
             table.insert(arr, part)
          elseif str ~= '' then
             str = str..part
          elseif length > 32*1024 then
             arr = {part}
          else
             str = part
          end
       end
    
       return arr and table.concat(arr) or str
    end
    -- remove \0 bytes from the end of the string
    function input_buffer_object.read_trimmed_string(length)
        local str = input_buffer_object.read_string(length)
        return str:gsub("%z*$", "")
        -- return trim()
    end
 
    function input_buffer_object.read_byte()
       return input_buffer_object.read_bytes(1)
    end
 
    function input_buffer_object.read_word()
       return input_buffer_object.read_words(1)
    end
 
    function input_buffer_object.read_bytes(quantity)
       return input_buffer_object.read_string(quantity):byte(1, -1)
    end
 
    function input_buffer_object.read_words(quantity)
       return unpack(input_buffer_object.read_array_of_words(quantity))
    end
 
    local function read_array_of_numbers_of_k_bytes_each(elems_in_array, k)
       if k == 1 and elems_in_array <= 100 then
          return {input_buffer_object.read_string(elems_in_array):byte(1, -1)}
       else
          local array_of_numbers = {}
          local max_numbers_in_string = floor(100 / k)
          for number_index = 1, elems_in_array, max_numbers_in_string do
             local numbers_in_this_part = math.min(elems_in_array - number_index + 1, max_numbers_in_string)
             local part = input_buffer_object.read_string(numbers_in_this_part * k)
             if k == 1 then
                for delta_index = 1, numbers_in_this_part do
                   array_of_numbers[number_index + delta_index - 1] = part:byte(delta_index)
                end
             else
                for delta_index = 0, numbers_in_this_part - 1 do
                   local number = 0
                   for byte_index = 1, k do
                      local pos = delta_index * k + (intel_byte_order and k + 1 - byte_index or byte_index)
                      number = number * 256 + part:byte(pos)
                   end
                   array_of_numbers[number_index + delta_index] = number
                end
             end
          end
          return array_of_numbers
       end
    end
 
    function input_buffer_object.read_array_of_words(elems_in_array)
       return read_array_of_numbers_of_k_bytes_each(elems_in_array, 2)
    end
 
    function input_buffer_object.read_u32()
        return bit32.bor(
            input_buffer_object.read_byte(),
            bit32.lshift(input_buffer_object.read_byte(), 8),
            bit32.lshift(input_buffer_object.read_byte(), 16),
            bit32.lshift(input_buffer_object.read_byte(), 24)
        )
    end

    function input_buffer_object.read_u16()
        return bit32.bor(
            input_buffer_object.read_byte(),
            bit32.lshift(input_buffer_object.read_byte(), 8))
    end
    function input_buffer_object.read_i16()
        local value = input_buffer_object.read_u16()
        if value >= 0x8000 then
            value = value - 0x10000
        end
        return value
    end
    return input_buffer_object
 
 end
 return open_file_buffer