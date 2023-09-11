import { Card, Flex, Text, Metric, Icon } from '@tremor/react'
import { ArrowLeftIcon } from '@heroicons/react/outline'
import { useNavigate } from 'react-router-dom'

function ContainerCard ({ children, title, subtitle, action, isSticky }) {
  const navigate = useNavigate()
  const className = isSticky ? 'fixed z-20 top-[85px] right-0 py-2' : 'py-2'
  return (
    <Card decoration='bottom' decorationColor='indigo' className={className}>
      <Flex justifyContent='between' className='gap-2 items-center justify-center'>
        <Icon
          className='cursor-pointer w-8 h-8 text-indigo-500'
          onClick={() => navigate(-1)}
          icon={ArrowLeftIcon}
        />

        <div className='flex-1 mt-4'>
          <Text>{subtitle}</Text>
          <Metric>{title}</Metric>
        </div>

        {action && (
          action
        )}
      </Flex>

      {children}
    </Card>
  )
}

export default ContainerCard
