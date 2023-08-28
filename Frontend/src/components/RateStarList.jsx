import { Flex, Icon } from '@tremor/react';
import { StarIcon as StarIcon } from '@heroicons/react/outline';
import { StarIcon as FillStarIcon } from '@heroicons/react/solid';

function RateStarList({ rate }) {
  const stars = [];
  for (let i = 0; i < 5; i += 1) {
    if (i >= rate) {
      stars.push(<Icon key={i} icon={StarIcon} />);
    } else {
      
      stars.push(<Icon key={i} icon={FillStarIcon} />);
    }
  }

  return (
    <Flex direction='row' gap={1} className='w-4'>
      {stars}
    </Flex>
  );
}

export default RateStarList;